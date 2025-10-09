const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const DynamoDB = new AWS.DynamoDB.DocumentClient();
const sharp = require('sharp');

const PARTITION_KEY = process.env.PARTITION_KEY || "user_id";
const SORT_KEY = process.env.SORT_KEY || "file_key";

exports.handler = async (event) => {
    try {
        console.log("Incoming event:", JSON.stringify(event, null, 2));

        const isBucketAVEnabled = process.env.BUCKET_AV_ENABLED || false;

        let bucket = "";
        let fileKey = "";
        if (isBucketAVEnabled === "true") {
            // Extract SNS message published by BucketAV
            const snsMessage = event.Records[0].Sns.Message;
            const message = JSON.parse(snsMessage);

            bucket = message.bucket;
            fileKey = message.key;
            const status = message.status;

            // Only process files in uploads/ folder
            const uploadFolder = (process.env.UPLOAD_FOLDER || "").trim().toLowerCase();
            const keyLower = fileKey.toLowerCase();
            if (!keyLower.startsWith(uploadFolder)) {
                console.log(`Skipping file ${fileKey} with status ${status}. (not under ${uploadFolder})`);
                return { statusCode: 200, body: "File skipped (not under uploads/)" };
            }
            
            // Only process "clean" files
            if (status !== "clean") {
                console.log(`Skipping file ${fileKey} with status ${status}. File skipped (not clean)`);
                return { statusCode: 200, body: "File skipped (not clean)" };
            }

        } else {
            // Extract bucket and key from the S3 event
            bucket = event.Records[0].s3.bucket.name;
            fileKey = event.Records[0].s3.object.key;
        }


        // Extract data from fileKey (uploads/trips/1/background.png)
        const keyParts = fileKey.split('/');
        const apiResource = keyParts[1];
        const partitionKey = keyParts[2];
        const filename = keyParts[keyParts.length - 1];

        // Download original image
        const originalObject = await S3.getObject({ Bucket: bucket, Key: fileKey }).promise();
        const originalBuffer = originalObject.Body;

        // Resize image to 200x200 thumbnail
        const thumbnailBuffer = await sharp(originalBuffer)
            .resize(200, 200)
            .toBuffer();

        // Define thumbnail key
        const thumbKey = `${process.env.THUMBNAIL_FOLDER}${apiResource}/${partitionKey}/${filename}`;

        // Upload thumbnail back to S3
        await S3.putObject({
            Bucket: bucket,
            Key: thumbKey,
            Body: thumbnailBuffer,
            ContentType: originalObject.ContentType
        }).promise();

        const tableName = process.env.DYNAMO_TABLE;

        // Query for existing items with selected = true for the same partitionKey
        // only one item per partitionKey/sortKey combination has selected = true
        const existing = await DynamoDB.query({
            TableName: tableName,
            KeyConditionExpression: "#pk = :pk",
            FilterExpression: "selected = :trueVal",
            ExpressionAttributeNames: { "#pk": PARTITION_KEY },
            ExpressionAttributeValues: { ":pk": partitionKey, ":trueVal": true }
        }).promise();

        const transactItems = [];

        // Set selected = false for existing item(s)
        existing.Items.forEach(item => {
            transactItems.push({
                Update: {
                    TableName: tableName,
                    Key: { [PARTITION_KEY]: item[PARTITION_KEY], [SORT_KEY]: item[SORT_KEY] },
                    UpdateExpression: "SET selected = :falseVal",
                    ExpressionAttributeValues: { ":falseVal": false }
                }
            });
        });

        // Put new item with selected = true
        const newItem = {
            [PARTITION_KEY]: partitionKey,
            [SORT_KEY]: fileKey,
            thumbnail_key: thumbKey,
            resource: apiResource,
            selected: true
        };

        transactItems.push({
            Put: {
                TableName: tableName,
                Item: newItem
            }
        });

        // Execute transaction
        await DynamoDB.transactWrite({ TransactItems: transactItems }).promise();

        return {
            statusCode: 200,
            body: `Thumbnail saved to ${bucket}/${thumbKey} and metadata recorded in DynamoDB`
        };

    } catch (err) {
        console.error("Error:", err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message })
        };
    }
};
