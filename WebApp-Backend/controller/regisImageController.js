const path = require("path");
const fs = require("fs");
const { v4: uuidv4 } = require("uuid");
const db = require("../config/database");
const sharp = require('sharp'); // For converting base64 image to JPEG buffer
const { exec } = require("child_process");

  
function base64ToVector(base64) {
    const vector = Array.from({ length: 128 }, () => Math.random().toFixed(6)); // Mock 128-dimension vector
    return vector;  
}
 
const detectFaceAndProcess = (base64Image) => {
  return new Promise((resolve, reject) => {
      console.log("[DEBUG] Starting detectFaceAndProcess...");

      const tempFile = path.join(__dirname, 'temp_image.jpg');
      const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");
      console.log(`[DEBUG] Writing temp image to: ${tempFile}`);
      fs.writeFileSync(tempFile, Buffer.from(base64Data, 'base64'));

      const command = `python /home/Vux/backend/model/face_crop.py ${tempFile}`;
      console.log(`[DEBUG] Running command: ${command}`); 
      exec(command, (error, stdout, stderr) => {
          if (error) {
              console.error(`[ERROR] Python script execution failed: ${stderr}`);
              return reject("Error processing face image.");
          }

          console.log("[DEBUG] Python script output received.");

          const originalMatch = stdout.match(/Original path:\s([^\n]+)/);
          const processedMatch = stdout.match(/Processed path:\s([^\n]+)/);
          const originalEmbeddingMatch = stdout.match(/Original embedding:\s([^\n]+)/);
          const processedEmbeddingMatch = stdout.match(/Processed embedding:\s([^\n]+)/);

          if (originalMatch && processedMatch && originalEmbeddingMatch && processedEmbeddingMatch) {
              console.log("[DEBUG] Successfully parsed Python script output.");
              resolve({
                  originalPath: originalMatch[1].trim(),
                  processedPath: processedMatch[1].trim(),
                  originalEmbedding: JSON.parse(originalEmbeddingMatch[1]),
                  processedEmbedding: JSON.parse(processedEmbeddingMatch[1]),
              });
          } else {
              console.error("[ERROR] Failed to parse Python script output.");
              reject("Face not processed correctly.");
          }
      });
  });
};

const createRegisterFace = async (req, res) => {
  try {
      console.log("[DEBUG] Starting createRegisterFace...");
      const { base64Image, member_id } = req.body;

      console.log(`[DEBUG] Request data: member_id=${member_id}, base64Image length=${base64Image ? base64Image.length : 0}`);

      if (!base64Image || !member_id) {
          console.error("[ERROR] Missing required fields.");
          return res.status(400).json({ message: "Base64 image and member_id are required!" });
      }

      console.log("[DEBUG] Querying database for member...");
      const [rows] = await db.promise().query(
          `SELECT account_id FROM tbl_member WHERE id = ?`,
          [member_id]
      );

      if (rows.length === 0) {
          console.error("[ERROR] Member not found.");
          return res.status(404).json({ message: "Member not found!" });
      }

      const account_id = rows[0].account_id;
      console.log(`[DEBUG] Found account_id: ${account_id}`);

      console.log("[DEBUG] Calling detectFaceAndProcess...");
      const { originalPath, processedPath, originalEmbedding, processedEmbedding } = await detectFaceAndProcess(base64Image);

      if (!originalPath || !processedPath) {
          console.error("[ERROR] Face not detected in the image.");
          return res.status(400).json({ message: "Face not detected in the image!" });
      }

      console.log("[DEBUG] Preparing file paths and directories...");
      const uniqueFileNameOriginal = `${uuidv4()}.jpg`;
      const uniqueFileNameProcessed = `processed_${uuidv4()}.jpg`;
      const uploadDirOriginal = path.join(__dirname, `../public/uploads/${account_id}`);
      const uploadDirProcessed = path.join(__dirname, `../public/process/${account_id}`);
      const imageUrlOriginal = `http://localhost:${process.env.PORT || 8888}/uploads/${account_id}/${uniqueFileNameOriginal}`;
      const imageUrlProcessed = `http://localhost:${process.env.PORT || 8888}/process/${account_id}/${uniqueFileNameProcessed}`;

      console.log(`[DEBUG] Upload paths: ${uploadDirOriginal}, ${uploadDirProcessed}`);

      if (!fs.existsSync(uploadDirOriginal)) fs.mkdirSync(uploadDirOriginal, { recursive: true });
      if (!fs.existsSync(uploadDirProcessed)) fs.mkdirSync(uploadDirProcessed, { recursive: true });

      fs.writeFileSync(path.join(uploadDirOriginal, uniqueFileNameOriginal), fs.readFileSync(originalPath));
      fs.writeFileSync(path.join(uploadDirProcessed, uniqueFileNameProcessed), fs.readFileSync(processedPath));

      console.log("[DEBUG] Formatting embeddings with account_id...");
      const formattedOriginalEmbedding = [[account_id], originalEmbedding];
      const formattedProcessedEmbedding = [[account_id], processedEmbedding];

      console.log("[DEBUG] Saving data to database...");
      const sql = `
          INSERT INTO tbl_register_faces (face_image, face_image_process, member_id, image_vector, image_vector_process)
          VALUES (?, ?, ?, ?, ?)
      `;
      await db.promise().query(sql, [
          imageUrlOriginal,
          imageUrlProcessed,
          member_id,
          JSON.stringify(formattedOriginalEmbedding),
          JSON.stringify(formattedProcessedEmbedding),
      ]);

      console.log("[DEBUG] Face registration successful.");
      res.status(201).json({
          message: "Face registration created successfully!",
          data: {
              face_image: imageUrlOriginal,
              face_image_process: imageUrlProcessed,
              member_id,
              account_id,
              image_vector: formattedOriginalEmbedding,
              image_vector_process: formattedProcessedEmbedding,
          },
      });
  } catch (error) {
      console.error("[ERROR] Error creating face registration:", error);
      res.status(500).json({ message: "Internal Server Error", error: error.message });
  }
};


// Function to get the image and its vector by member_id
const getImageByID = async (req, res) => {
  const { memberId } = req.params;
  console.log('Extracted ID:', memberId);

  if (!memberId) {
    return res.status(400).json({ error: 'Member ID is required' });
  }

  try {
    // Query to get face image and vector by member_id
    const query = 'SELECT id, face_image, image_vector, face_image_process, image_vector_process FROM tbl_register_faces WHERE member_id = ?';
    const [results] = await db.promise().query(query, [memberId]);

    if (results.length === 0) {
      return res.status(404).json({ error: 'No data found for the given member_id' });
    }

    // Prepare response data by mapping over all rows
    const response = results.map(row => {
      let parsedVector;
      try {
        parsedVector = Array.isArray(row.image_vector) ? row.image_vector : JSON.parse(row.image_vector);
      } catch (error) {
        console.error('Error parsing image_vector:', error);
        throw new Error('Failed to process image_vector');
      }
      return {
        id: row.id,
        face_image_url: row.face_image,
        image_vector: parsedVector,
        face_image_process: row.face_image_process,
        image_vector_process:row.image_vector_process
      };
    });

    // Respond with all rows data
    res.status(200).json(response);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const getAllDataWithUsername = async (req, res) => {
  try {
    // Query to get all data from tbl_register_faces and join with tbl_member to get the username
    const query = `
      SELECT 
    r.id AS register_face_id,
    r.member_id, 
    r.face_image, 
    r.image_vector, 
    r.face_image_process, 
    r.image_vector_process,
    m.account_id AS username,
    a.status
    FROM tbl_register_faces r
    LEFT JOIN tbl_member m ON r.member_id = m.id
    LEFT JOIN tbl_account a ON m.account_id = a.username;
    `;
    const [results] = await db.promise().query(query);

    if (results.length === 0) {
      return res.status(404).json({ error: 'No data found in the database' });
    }

    // Prepare response data by mapping over all rows
    const response = results.map(row => {
      let parsedVector = null;

      // Safely parse image_vector
      if (row.image_vector) {
        try {
          parsedVector = Array.isArray(row.image_vector)
            ? row.image_vector
            : JSON.parse(row.image_vector);
        } catch (error) {
          console.error('Error parsing image_vector for ID ${row.register_face_id}:', error);
        }
      }

      return {
        id: row.register_face_id, // Unique ID for the register face
        member_id: row.member_id,
        status: row.status,
        username: row.username, // Username from the member table
        face_image_url: row.face_image, // Face image URL
        image_vector: parsedVector, // Parsed or null
        face_image_process: row.face_image_process, // Face processing image URL
        image_vector_process: row.image_vector_process, // Processed vector data
      };
    });

    // Respond with all rows data
    res.status(200).json(response);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
};

const deleteRegisterFace = (req, res) => {
    try {
      const { id } = req.params; // Get the id from the request params
  
      if (!id) {
        return res.status(400).json({ message: "ID is required!" });
      }
  
      // Step 1: Get the face_image URL from the database
      db.query("SELECT face_image FROM tbl_register_faces WHERE id = ?", [id], (err, rows) => {
        if (err) {
          console.error("Error querying the database:", err);
          return res.status(500).json({ message: "Internal Server Error" });
        }
  
        if (!rows.length) {
          return res.status(404).json({ message: "Face registration not found" });
        }
  
        const faceImageUrl = rows[0].face_image;
  
        // Step 2: Extract the image file name from the URL
        const imageFileName = path.basename(faceImageUrl); // Extract file name from URL
        
        // Extract accountId more robustly from the URL
        const accountId = faceImageUrl.split("/").slice(-2, -1)[0];
  
        // Step 3: Construct the path to the image file on the server
        const imageFilePath = path.join(__dirname, `../public/uploads/${accountId}`, imageFileName);
  
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
        db.query("DELETE FROM tbl_register_faces WHERE id = ?", [id], (deleteErr, deleteResult) => {
          if (deleteErr) {
            console.error("Error deleting database record:", deleteErr);
            return res.status(500).json({ message: "Internal Server Error" });
          }
  
          res.status(200).json({
            message: "Face registration and image deleted successfully",
          });
        });
      });
    } catch (error) {
      console.error("Unexpected error:", error);
      res.status(500).json({ message: "Internal Server Error", error: error.message });
    }
  };



const getFaceRegistrationStats = async (req, res) => {
    try {
        const queryRegistered = `
            SELECT COUNT(DISTINCT m.id) AS registered_count
            FROM tbl_member m
            INNER JOIN tbl_register_faces rf ON m.id = rf.member_id;
        `;

        const queryNotRegistered = `
            SELECT COUNT(*) AS not_registered_count
            FROM tbl_member m
            WHERE NOT EXISTS (
                SELECT 1 FROM tbl_register_faces rf
                WHERE m.id = rf.member_id
            );
        `;

        // Execute both queries
        const [registeredRows] = await db.promise().query(queryRegistered);
        const [notRegisteredRows] = await db.promise().query(queryNotRegistered);

        // Extract counts
        const registeredCount = registeredRows[0].registered_count;
        const notRegisteredCount = notRegisteredRows[0].not_registered_count;

        // Send the response
        res.json({
            success: true,
            data: {
                registeredCount,
                notRegisteredCount,
            },
        });
    } catch (error) {
        console.error("Error fetching face registration stats:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch face registration stats",
        });
    }
};


module.exports = { 
    createRegisterFace,
    deleteRegisterFace,
    getImageByID,
    detectFaceAndProcess,
    getAllDataWithUsername,
    getFaceRegistrationStats
};
