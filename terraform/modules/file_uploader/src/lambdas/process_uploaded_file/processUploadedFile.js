const AWS = require("aws-sdk");
const S3 = new AWS.S3();
const DynamoDB = new AWS.DynamoDB.DocumentClient();
const sharp = require("sharp");

const PARTITION_KEY = process.env.PARTITION_KEY || "id";
const SORT_KEY = process.env.SORT_KEY || "file_key";
const TABLE_NAME = process.env.DYNAMO_TABLE;

const NAMESPACE = "Custom/MetadataWriter";
const cloudwatch = new AWS.CloudWatch();

/**
 * CloudWatch Metric Helper
 */
async function emitMetric(metricName, value, unit = "Count") {
    try {
        await cloudwatch
            .putMetricData({
                Namespace: NAMESPACE,
                MetricData: [
                    {
                        MetricName: metricName,
                        Value: value,
                        Unit: unit,
                        Dimensions: [
                            { Name: "TableName", Value: TABLE_NAME }
                        ]
                    }
                ]
            })
            .promise();
    } catch (err) {
        console.error(`❌ Failed to publish metric ${metricName}:`, err);
    }
}

exports.handler = async (event) => {
    try {
        console.log("Incoming event:", JSON.stringify(event, null, 2));

        const isBucketAVEnabled = process.env.BUCKET_AV_ENABLED || false;

        let bucket = "";
        let fileKey = "";

        if (isBucketAVEnabled === "true") {
            // BucketAV SNS message
            const snsMessage = event.Records[0].Sns.Message;
            const message = JSON.parse(snsMessage);

            bucket = message.bucket;
            fileKey = message.key;

            const uploadFolder = (process.env.UPLOAD_FOLDER || "").trim().toLowerCase();
            const keyLower = fileKey.toLowerCase();

            if (!keyLower.startsWith(uploadFolder)) {
                console.log(`Skipping (outside upload folder): ${fileKey}`);
                return { statusCode: 200, body: "File skipped" };
            }

            if (message.status !== "clean") {
                console.log(`Skipping non-clean file: ${fileKey}`);
                return { statusCode: 200, body: "File skipped (not clean)" };
            }
        } else {
            // Simple S3 trigger
            bucket = event.Records[0].s3.bucket.name;
            fileKey = event.Records[0].s3.object.key;
        }

        // ------------ Parse Key: uploads/trips/1/background.png ------------
        const keyParts = fileKey.split("/");
        const apiResource = keyParts[1];
        const partitionKey = keyParts[2];
        const filename = keyParts[keyParts.length - 1];

        // ------------ Download file ------------
        const { ContentType, Body } = await S3.getObject({
            Bucket: bucket,
            Key: fileKey,
        }).promise();

        // ------------ Thumbnail generation ------------
        let thumbKey = null;

        if (ContentType && ContentType.startsWith("image/")) {
            console.log(`Generating thumbnail for: ${fileKey}`);

            const thumbnailBuffer = await sharp(Body)
                .resize(200, 200)
                .toBuffer();

            thumbKey = `${process.env.THUMBNAIL_FOLDER}${apiResource}/${partitionKey}/${filename}`;

            await S3.putObject({
                Bucket: bucket,
                Key: thumbKey,
                Body: thumbnailBuffer,
                ContentType: ContentType,
            }).promise();
        }

        // ------------ DynamoDB metadata write ------------
        const dynamoStart = Date.now();

        try {
            // Fetch existing selected=true items for same partitionKey
            const existing = await DynamoDB.query({
                TableName: TABLE_NAME,
                KeyConditionExpression: "#pk = :pk",
                FilterExpression: "selected = :trueVal",
                ExpressionAttributeNames: {
                    "#pk": PARTITION_KEY
                },
                ExpressionAttributeValues: {
                    ":pk": partitionKey,
                    ":trueVal": true
                }
            }).promise();

            const transactItems = [];

            // Set previous selected=true → false
            existing.Items.forEach((item) => {
                transactItems.push({
                    Update: {
                        TableName: TABLE_NAME,
                        Key: {
                            [PARTITION_KEY]: item[PARTITION_KEY],
                            [SORT_KEY]: item[SORT_KEY],
                        },
                        UpdateExpression: "SET selected = :falseVal",
                        ExpressionAttributeValues: { ":falseVal": false },
                    },
                });
            });

            // Insert new item with selected=true
            const newItem = {
                [PARTITION_KEY]: partitionKey,
                [SORT_KEY]: fileKey,
                thumbnail_key: thumbKey,
                resource: apiResource,
                selected: true,
            };

            transactItems.push({
                Put: {
                    TableName: TABLE_NAME,
                    Item: newItem,
                },
            });

            await DynamoDB.transactWrite({
                TransactItems: transactItems,
            }).promise();

            await emitMetric("DynamoWrites", 1);
        } catch (err) {
            console.error("DynamoDB error:", err);

            await emitMetric("DynamoWriteFailed", 1);

            // Optional: latency metric even on failure
            await emitMetric("DynamoLatency", Date.now() - dynamoStart, "Milliseconds");

            throw err;
        }

        // Dynamo latency metric (success path)
        await emitMetric("DynamoLatency", Date.now() - dynamoStart, "Milliseconds");

        return {
            statusCode: 200,
            body: `Metadata recorded & thumbnail saved: ${thumbKey}`,
        };

    } catch (err) {
        console.error("Fatal Error:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message }),
        };
    }
};
