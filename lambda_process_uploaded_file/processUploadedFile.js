const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const DynamoDB = new AWS.DynamoDB.DocumentClient();

const sharp = require('sharp');

exports.handler = async (event) => {
    try {
        // Extract bucket and key from the S3 event
        const bucket = event.Records[0].s3.bucket.name;
        const fileKey = event.Records[0].s3.object.key;

        // Extract user_id from the key or metadata (adjust this based on your naming convention)
        // Example: user123/background.png -> userId = user123
        const keyParts = fileKey.split('/');
        const userId = keyParts[1];
        const filename = keyParts[keyParts.length - 1];

        // Download original image
        const originalObject = await S3.getObject({ Bucket: bucket, Key: fileKey }).promise();
        const originalBuffer = originalObject.Body;

        // Resize image to 200x200 thumbnail
        const thumbnailBuffer = await sharp(originalBuffer)
            .resize(200, 200)
            .toBuffer();

        // Define thumbnail key
        const thumbKey = `${process.env.THUMBNAIL_FOLDER}${userId}/${filename}`;

        // Upload thumbnail back to S3
        await S3.putObject({
            Bucket: bucket,
            Key: thumbKey,
            Body: thumbnailBuffer,
            ContentType: originalObject.ContentType
        }).promise();

        // Save record in DynamoDB
        const tableName = process.env.DYNAMO_TABLE; 
        const item = {
            file_key: fileKey, // Partition key
            user_id: userId, // Sort key           
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
        console.error(err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message })
        };
    }
};
