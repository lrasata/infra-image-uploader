const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const DynamoDB = new AWS.DynamoDB.DocumentClient();
const sharp = require('sharp');

const PARTITION_KEY = process.env.PARTITION_KEY || "user_id";

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


        // Extract user_id from fileKey (uploads/user123/background.png)
        const keyParts = fileKey.split('/');
        const partitionKey = keyParts[1];
        const filename = keyParts[keyParts.length - 1];

        // Download original image
        const originalObject = await S3.getObject({ Bucket: bucket, Key: fileKey }).promise();
        const originalBuffer = originalObject.Body;

        // Resize image to 200x200 thumbnail
        const thumbnailBuffer = await sharp(originalBuffer)
            .resize(200, 200)
            .toBuffer();

        // Define thumbnail key
        const thumbKey = `${process.env.THUMBNAIL_FOLDER}${partitionKey}/${filename}`;

        // Upload thumbnail back to S3
        await S3.putObject({
            Bucket: bucket,
            Key: thumbKey,
            Body: thumbnailBuffer,
            ContentType: originalObject.ContentType
        }).promise();

        // Save metadata to DynamoDB
        const tableName = process.env.DYNAMO_TABLE;
        const item = {
            file_key: fileKey,   // partition key
            [PARTITION_KEY]: partitionKey,     // sort key
            thumbnail_key: thumbKey
        };

        await DynamoDB.put({
            TableName: tableName,
            Item: item
        }).promise();

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
