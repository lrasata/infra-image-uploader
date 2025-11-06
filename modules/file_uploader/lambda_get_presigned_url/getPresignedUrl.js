const AWS = require("aws-sdk");
const crypto = require("crypto");

const REGION = process.env.REGION || "eu-central-1";
const BUCKET_NAME = process.env.UPLOAD_BUCKET || "s3-bucket-name";
const UPLOAD_FOLDER = process.env.UPLOAD_FOLDER || "uploads/";
const EXPIRATION_TIME_S = parseInt(process.env.EXPIRATION_TIME_S || "300");
const API_GW_AUTH_SECRET = process.env.API_GW_AUTH_SECRET;
const PARTITION_KEY = process.env.PARTITION_KEY || "user_id";
const SORT_KEY = process.env.SORT_KEY || "file_key";

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

    // Client must send tripId, filename, extension, resource (name in plurals)
    const partitionKey = query[PARTITION_KEY];
    const originalFilename = query[SORT_KEY];
    const extension = query.ext;
    const apiResource = query.resource;

    if (!partitionKey || !originalFilename || !extension) {
        return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: "Query params could be missing" })
        };
    }

    try {
        // Generate a random unique filename
        const randomId = crypto.randomBytes(16).toString("base64url"); // URL-safe base64

        // Build key: uploads/<resource>/<partition_key>/<randomId>_<filename>.<extension>
        const fileKey = `${UPLOAD_FOLDER}${apiResource}/${partitionKey}/${randomId}_${originalFilename}${extension ? "." + extension : ""}`;

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
