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

const detectFaceAndCrop = (base64Image) => {
    return new Promise((resolve, reject) => {
        const tempFile = path.join(__dirname, 'temp_image.jpg');
        const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, "");
        fs.writeFileSync(tempFile, Buffer.from(base64Data, 'base64'));

        exec(`python E:\\.kltn\\source_code\\backend\\model\\face_crop.py ${tempFile}`, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error: ${error.message}`);
                return reject(error);
            }
            if (stderr) {
                console.error(`stderr: ${stderr}`);
                return reject(stderr);
            }

            console.log('Python script output:', stdout); // This should now include the full path

            // Extract the path from the Python output using a regular expression
            const match = stdout.match(/Saved to:\s([^\n]+)/);
            if (match) {
                const croppedImagePath = match[1].trim();
                console.log('Cropped image path:', croppedImagePath); // Log cropped image path for debugging

                if (fs.existsSync(croppedImagePath)) {
                    // Read and convert the cropped image to base64
                    const croppedImageData = fs.readFileSync(croppedImagePath);
                    const croppedBase64 = croppedImageData.toString('base64');
                    resolve(`data:image/jpeg;base64,${croppedBase64}`);
                } else {
                    console.error('Error: Cropped image not found at path:', croppedImagePath);
                    reject("Face not cropped correctly.");
                }
            } else {
                console.error('Error: Could not extract the cropped image path from the Python output.');
                reject("Face not cropped correctly.");
            }
        });
    });
};

const createRegisterFace = async (req, res) => {
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

        // Step 2: Detect face and crop if detected
        const croppedBase64Image = await detectFaceAndCrop(base64Image);

        if (!croppedBase64Image) {
            return res.status(400).json({ message: "No face detected in the image!" });
        }

        // Step 3: Convert base64 to image buffer and save as JPEG
        const base64Data = croppedBase64Image.replace(/^data:image\/\w+;base64,/, "");
        
        // Convert base64 to buffer and ensure it's in JPEG format using sharp
        const imageBuffer = await sharp(Buffer.from(base64Data, "base64"))
            .jpeg() // Convert to JPEG
            .toBuffer();

        const uniqueFileName = `${uuidv4()}.jpg`;
        const uploadDir = path.join(__dirname, `../public/uploads/${account_id}`);
        const imagePath = path.join(uploadDir, uniqueFileName);
        const imageUrl = `http://localhost:${process.env.PORT || 8888}/uploads/${account_id}/${uniqueFileName}`;

        // Ensure the directory exists
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        // Save the image file
        fs.writeFileSync(imagePath, imageBuffer);

        // Step 4: Generate the image vector
        const imageVector = base64ToVector(base64Image);

        // Step 5: Insert into tbl_register_faces
        const sql = `
            INSERT INTO tbl_register_faces (face_image, member_id, image_vector)
            VALUES (?, ?, ?)
        `;
        await db.promise().query(sql, [imageUrl, member_id, JSON.stringify(imageVector)]);

        // Respond with success
        res.status(201).json({
            message: "Face registration created successfully!",
            data: {
                face_image: imageUrl,
                member_id,
                account_id,
                image_vector: imageVector,
            },
        });
    } catch (error) {
        console.error("Error creating face registration:", error);
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
    const query = 'SELECT id, face_image, image_vector FROM tbl_register_faces WHERE member_id = ?';
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
  


module.exports = { 
    createRegisterFace,
    deleteRegisterFace,
    detectFaceAndCrop,
    getImageByID
};
