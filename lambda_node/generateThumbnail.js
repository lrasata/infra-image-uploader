// index.js
const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const sharp = require('sharp');

exports.handler = async (event) => {
    try {
        // Extract bucket and key from the S3 event
        const bucket = event.Records[0].s3.bucket.name;
        const key = event.Records[0].s3.object.key;

        // Download original image
        const originalObject = await S3.getObject({ Bucket: bucket, Key: key }).promise();
        const originalBuffer = originalObject.Body;

        // Resize image to 200x200 thumbnail
        const thumbnailBuffer = await sharp(originalBuffer)
            .resize(200, 200)
            .toBuffer();

        // Define thumbnail key
        const keyParts = key.split('/');
        const filename = keyParts[keyParts.length - 1];
        const thumbKey = `thumbnails/${filename}`;

        // Upload thumbnail back to S3
        await S3.putObject({
            Bucket: bucket,
            Key: thumbKey,
            Body: thumbnailBuffer,
            ContentType: originalObject.ContentType
        }).promise();

        return {
            statusCode: 200,
            body: `Thumbnail saved to ${bucket}/${thumbKey}`
        };
    } catch (err) {
        console.error(err);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: err.message })
        };
    }
};
