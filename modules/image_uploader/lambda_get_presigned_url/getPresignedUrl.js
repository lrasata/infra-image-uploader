const AWS = require("aws-sdk");
const crypto = require("crypto");

const REGION = process.env.REGION || "eu-central-1";
const BUCKET_NAME = process.env.UPLOAD_BUCKET || "s3-bucket-name";
const UPLOAD_FOLDER = process.env.UPLOAD_FOLDER || "uploads/";
const EXPIRATION_TIME_S = parseInt(process.env.EXPIRATION_TIME_S || "300");
const API_GW_AUTH_SECRET = process.env.API_GW_AUTH_SECRET;

const s3 = new AWS.S3({
    region: REGION,
    signatureVersion: "v4",
    useAccelerateEndpoint: process.env.USE_S3_ACCEL === "true"
});

const corsHeaders = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,x-api-gateway-img-upload-auth",
    "Access-Control-Allow-Methods": "GET,OPTIONS,PUT",
};

exports.handler = async (event) => {
    const headers = event.headers || {};
    const customHeader = headers["x-api-gateway-img-upload-auth"];

    if (customHeader !== API_GW_AUTH_SECRET) {
        return {
            statusCode: 403,
            headers: corsHeaders,
            body: JSON.stringify({ error: "Forbidden: Invalid or missing custom auth header" }),
        };
    }

    const query = event.queryStringParameters || {};

    // Client must send userId, filename, extension
    const userId = query.userId;
    const originalFilename = query.filename;
    const extension = query.ext;

    if (!userId || !originalFilename || !extension) {
        return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: "Query params could be missing" })
        };
    }

    try {
        // Generate a random unique filename
        const randomId = crypto.randomBytes(16).toString("base64url"); // URL-safe base64

        // Build key: uploads/<user_id>/<randomId>_<filename>.<extension>
        const fileKey = `${UPLOAD_FOLDER}${userId}/${randomId}_${originalFilename}${extension ? "." + extension : ""}`;

        // Generate presigned PUT URL
        const presignedUrl = s3.getSignedUrl("putObject", {
            Bucket: BUCKET_NAME,
            Key: fileKey,
            Expires: EXPIRATION_TIME_S
        });

        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({
                upload_url: presignedUrl,
                file_key: fileKey
            })
        };

    } catch (error) {
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ error: error.message })
        };
    }
};
