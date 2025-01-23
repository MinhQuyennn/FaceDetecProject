const path = require("path");
const fs = require("fs");
const { v4: uuidv4 } = require("uuid");
const db = require("../config/database");
const sharp = require('sharp'); // For converting base64 image to JPEG buffer
const { exec } = require("child_process");

const { spawn } = require('child_process');

// Đường dẫn đến file Python
const pythonScript = '/home/Vux/backend/model/detect.py'; // Thay đổi theo tên file Python của bạn

// Gọi Python script
const pythonProcess = spawn('python', [pythonScript]);

// Đọc dữ liệu từ Python
pythonProcess.stdout.on('data', (data) => {
    console.log(`Output: ${data}`);
});

// Xử lý lỗi
pythonProcess.stderr.on('data', (data) => {
    console.error(`Error: ${data}`);
});

// Xử lý khi Python script kết thúc
pythonProcess.on('close', (code) => {
    console.log(`Python script ended with code ${code}`);
});


const createEnterHistory = async (req, res) => {
    try {
        const { base64Image, member_id } = req.body;

        if (!base64Image || !member_id) {
            return res.status(400).json({ message: "Base64 image and member_id are required!" });
        }

        // Step 1: Retrieve account_id from tbl_member
        const [rows] = await db.promise().query(
            `SELECT account_id FROM tbl_member WHERE id = ?`,
            [member_id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: "Member not found!" });
        }

        const account_id = rows[0].account_id;

        // Step 2: Convert base64 image to buffer and save as JPEG
        const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");
        const imageBuffer = await sharp(Buffer.from(base64Data, "base64"))
            .jpeg() // Ensure the image is in JPEG format
            .toBuffer();

        const uniqueFileName = `${uuidv4()}.jpg`;
        const uploadDir = path.join(__dirname, `../public/histories/${account_id}`);
        const imagePath = path.join(uploadDir, uniqueFileName);
        const imageUrl = `http://localhost:${process.env.PORT || 8888}/histories/${account_id}/${uniqueFileName}`;

        // Ensure the directory exists
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        // Save the image file
        fs.writeFileSync(imagePath, imageBuffer);

        // Step 3: Insert data into tbl_enter_history
        const sql = `
            INSERT INTO tbl_enter_history (member_id, face_image)
            VALUES (?, ?)
        `;
        await db.promise().query(sql, [member_id, imageUrl]);

        // Respond with success
        res.status(201).json({
            message: "Entry history created successfully!",
            data: {
                member_id,
                face_image: imageUrl,
            },
        });
    } catch (error) {
        console.error("Error creating entry history:", error);
        res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
};

const deleteHistories = (req, res) => {
    try {
        const { id } = req.params; // Get the id from the request params

        if (!id) {
            return res.status(400).json({ message: "ID is required!" });
        }

        // Step 1: Get the face_image URL from the database
        db.query("SELECT face_image FROM tbl_enter_history WHERE id = ?", [id], (err, rows) => {
            if (err) {
                console.error("Error querying the database:", err);
                return res.status(500).json({ message: "Internal Server Error" });
            }

            if (!rows.length) {
                return res.status(404).json({ message: "History record not found" });
            }

            const faceImageUrl = rows[0].face_image;

            // Step 2: Extract the image file name and account ID from the URL
            const imageFileName = path.basename(faceImageUrl); // Extract file name from URL
            const accountId = faceImageUrl.split("/").slice(-2, -1)[0]; // Extract accountId

            // Step 3: Construct the path to the image file on the server
            const imageFilePath = path.join(__dirname, `../public/histories/${accountId}`, imageFileName);

            // Step 4: Delete the image file from the server (if it exists)
            if (fs.existsSync(imageFilePath)) {
                fs.unlink(imageFilePath, (fsErr) => {
                    if (fsErr) {
                        console.error("Error deleting image file:", fsErr);
                    } else {
                        console.log(`Deleted image: ${imageFilePath}`);
                    }
                });
            } else {
                console.log(`Image not found at: ${imageFilePath}`);
            }

            // Step 5: Delete the record from the database
            db.query("DELETE FROM tbl_enter_history WHERE id = ?", [id], (deleteErr, deleteResult) => {
                if (deleteErr) {
                    console.error("Error deleting database record:", deleteErr);
                    return res.status(500).json({ message: "Internal Server Error" });
                }

                res.status(200).json({
                    message: "History record and image deleted successfully",
                });
            });
        });
    } catch (error) {
        console.error("Unexpected error:", error);
        res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
};

const getAllHistories = (req, res) => {
    try {
        // Query to fetch all records from tbl_enter_history
        db.query("SELECT h.id,h.enter_at,h.member_id,h.face_image,m.account_id FROM tbl_enter_history h JOIN tbl_member m ON h.member_id = m.id", (err, rows) => {
            if (err) {
                console.error("Error querying the database:", err);
                return res.status(500).json({ message: "Internal Server Error" });
            }

            // Check if no data is found
            if (!rows.length) {
                return res.status(404).json({ message: "No history records found" });
            }

            // Respond with all data
            res.status(200).json({
                message: "History records retrieved successfully",
                data: rows,
            });
        });
    } catch (error) {
        console.error("Unexpected error:", error);
        res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
};

const getHistoriesByMemberId = (req, res) => {
    try {
        const { id } = req.params; // Use 'id' to match the route parameter

        if (!id) {
            return res.status(400).json({ message: "Member ID is required!" });
        }

        // Query to fetch records from tbl_enter_history by member_id
        db.query("SELECT * FROM tbl_enter_history WHERE member_id = ?", [id], (err, rows) => {
            if (err) {
                console.error("Error querying the database:", err);
                return res.status(500).json({ message: "Internal Server Error" });
            }

            // Check if no data is found
            if (!rows.length) {
                return res.status(404).json({ message: "No history records found for this member" });
            }

            // Respond with the data
            res.status(200).json({
                message: "History records retrieved successfully",
                data: rows,
            });
        });
    } catch (error) {
        console.error("Unexpected error:", error);
        res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
};


module.exports = { 
    createEnterHistory,
    deleteHistories,
    getAllHistories,
    getHistoriesByMemberId
};
