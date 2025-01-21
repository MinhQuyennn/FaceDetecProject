// controllers/AuthController.js
const db = require("../config/database");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
// const validateRegisterInput = require("../validator/RegisterValidator");
require("dotenv").config();

const login = async (req, res, next) => {
    const { username, password } = req.body;
    
    // Check if username and password are provided
    if (!username || !password) {
        return res.status(400).json({
            status: "failed",
            error: "Username and password are required",
        });
    }

    const sql = `SELECT * FROM tbl_account WHERE username = ?`;

    db.query(sql, [username], (err, result) => {
        if (err) {
            return res.status(500).json({
                status: "failed",
                error: "Internal Server Error",
            });
        }

        if (result.length === 0) {
            return res.status(404).json({
                status: "failed",
                error: "Account not found", 
            });
        }

        const tbl_account = result[0];

        // Check if user account is enabled
        if (tbl_account.status !== 'able') { 
            return res.status(403).json({
                status: "failed",
                error: "Account is disabled",
            });
        }

        // Verify password (hashed password comparison)
        bcrypt.compare(password, tbl_account.password, (err, isMatch) => {
            if (err) {
                return res.status(500).json({
                    status: "failed",
                    error: "Error comparing passwords",
                });
            }

            if (!isMatch) {
                return res.status(401).json({
                    status: "failed",
                    error: "Invalid password",
                });
            }

            // Payload for JWT
            const payload = {
                username: tbl_account.username,
                role: tbl_account.role,
            };

            // Sign JWT token
            console.log("Payload: ", payload);
console.log("Secret Key: ", process.env.JWT_SECRET_KEY);

jwt.sign(payload, process.env.JWT_SECRET_KEY, { expiresIn: '1h' }, (err, token) => {
    if (err) {
        console.error("JWT Error: ", err);
        return res.status(500).json({
            status: "failed",
            error: "Token generation failed",
        });
    }

    res.json({
        status: "success",
        token: token,
        role: tbl_account.role,
    });
});
        });
    });
};


const signUp = async (req, res, next) => {
  const { username, password, role , status } = req.body;

  // Check if the username already exists
  const checkUsernameQuery = 'SELECT * FROM tbl_account WHERE username = ?';
  db.query(checkUsernameQuery, [username], async (err, result) => {
    if (err) {
      return res.status(500).json({
        status: 'failed',
        error: 'Internal Server Error',
      });
    }

    if (result.length > 0) {
      return res.status(401).json({
        status: 'error',
        message: 'Username already exists.',
      });
    }

    // Hash the password before saving to the database
    try {
      const hashedPassword = await bcrypt.hash(password, 10); // Salt rounds set to 10

      // Insert the new account with the given role and status
      const insertAccountQuery = `
        INSERT INTO tbl_account (username, password, role, status)
        VALUES (?, ?, ?, ?)
      `;
      const newUserValues = [username, hashedPassword, role, status];

      db.query(insertAccountQuery, newUserValues, (err, result) => {
        if (err) {
          return res.status(400).json({
            status: 'failed',
            error: 'Bad Request',
          });
        }

        res.json({
          status: 'success',
          message: 'Successfully created account!1',
          username: username,
        });
      });
    } catch (hashError) {
      return res.status(500).json({
        status: 'failed',
        error: 'Error hashing password',
      });
    }
  });
};



module.exports = {
  login,
  signUp
};