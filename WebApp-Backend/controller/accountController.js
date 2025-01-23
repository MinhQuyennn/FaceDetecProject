const db = require("../config/database");
const express = require("express");
const bcrypt = require('bcrypt'); // Import bcrypt for password hashing

const getAccount = async (req, res) => {
  const sql = "SELECT * FROM tbl_account";
  db.query(sql, (err, result) => {
    if (err) {
      return res.status(500).json({ Error: "Error fetching account" });
    }
    return res.status(200).json({ Status: "Success", accounts: result });
  });
}; 

const getAllInforAcc = async (req, res) => {
    const sql = "SELECT a.username, a.role, a.status, m.id, m.name AS member_name, m.address, m.phone_number, m.email, p.name AS position_name FROM tbl_account a JOIN tbl_member m ON a.username = m.account_id JOIN tbl_position p ON m.position_id = p.id;";
    db.query(sql, (err, result) => {
      if (err) {
        return res.status(500).json({ Error: "Error fetching account" });
      }
      return res.status(200).json({ Status: "Success", accountsInfo: result });
    });
  };

  const getAccountById = async (req, res) => {
    const accountId = req.params.account_id; // Get account_id from request parameters
    const sql = "SELECT a.username, a.role, a.status, m.id, m.name AS member_name, m.address, m.phone_number, m.email, p.name AS position_name FROM tbl_account a JOIN tbl_member m ON a.username = m.account_id JOIN tbl_position p ON m.position_id = p.id WHERE a.username = ?;";

    db.query(sql, [accountId], (err, result) => {
        if (err) {
            return res.status(500).json({ Error: "Error fetching account" });
        }
        if (result.length === 0) {
            return res.status(404).json({ Error: "Account not found" });
        }
        return res.status(200).json({ Status: "Success", accountInfo: result[0] });
    });
};


  const updateaccountusername = async (req, res) => {
      const username = req.params.username; // Get the username (id) from the URL parameters
      const { status, role, password } = req.body;  // Extract values from the request body
  
      // Start building the SQL query dynamically
      let sql = "UPDATE tbl_account SET";
      let values = [];
      let updateFields = []; // Array to track update fields
  
      // Add fields to the query if they're provided in the request
      if (status) {
          updateFields.push("status = ?");
          values.push(status);
      }
      
      if (role) {
          updateFields.push("role = ?");
          values.push(role);
      }
      
      if (password) {
          try {
              // Hash the password before storing it
              const hashedPassword = await bcrypt.hash(password, 10); // 10 is the salt rounds
              updateFields.push("password = ?");
              values.push(hashedPassword);
          } catch (error) {
              console.error("Error hashing password:", error);
              return res.status(500).json({ Error: "Internal server error during password hashing" });
          }
      }
  
      // If no fields to update, return an error response
      if (updateFields.length === 0) {
          return res.status(400).json({ Error: "No fields to update" });
      }
  
      // Construct the SQL query dynamically
      sql += ` ${updateFields.join(", ")} WHERE username = ?`;
      values.push(username); // The username (id) parameter for the WHERE clause
      
      // Perform the query
      db.query(sql, values, (err, result) => {
          if (err) {
              console.error("Error updating account:", err);
              return res.status(500).json({ Error: "Internal server error" });
          }
  
          // Check if the account was updated (affected rows > 0)
          if (result.affectedRows > 0) {
              return res.status(200).json({ Status: "Account updated successfully" });
          } else {
              return res.status(404).json({ Error: "Account not found" });
          }
      });
  };

const getAccByFilter = async (req, res) => {
    const { username, email, role } = req.query;  // Get parameters from query string

    // Start building the SQL query with a JOIN between tbl_account, tbl_member, and tbl_position
    let sql = `
        SELECT 
            tbl_account.username, 
            tbl_account.password, 
            tbl_account.role, 
            tbl_account.status, 
            tbl_account.email, 
            tbl_member.id AS member_id, 
            tbl_member.name AS member_name, 
            tbl_member.address, 
            tbl_member.phone_number, 
            tbl_member.email AS member_email, 
            tbl_position.name AS position_name
        FROM tbl_account
        JOIN tbl_member ON tbl_account.username = tbl_member.account_id
        LEFT JOIN tbl_position ON tbl_member.position_id = tbl_position.id
        WHERE
    `;
    let values = [];
    let conditions = [];  // This will store our conditions dynamically

    // Check which parameters are provided and build the query accordingly
    if (username) {
        conditions.push("tbl_account.username = ?");
        values.push(username);
    }

    if (email) {
        conditions.push("tbl_account.email = ?");
        values.push(email);
    }

    if (role) {
        conditions.push("tbl_account.role = ?");
        values.push(role);
    }

    // If no query parameters are provided, send a bad request response
    if (conditions.length === 0) {
        return res.status(400).json({ Error: "Please provide username, email, or role to search." });
    }

    // Join all conditions with OR to allow for multiple conditions to be matched
    sql += conditions.join(" OR ");

    // Perform the query   
    db.query(sql, values, (err, result) => {
        if (err) {
            console.error("Error fetching account:", err);
            return res.status(500).json({ Error: "Internal server error" });
        }

        // Check if any accounts were found
        if (result.length > 0) {
            return res.status(200).json(result);
        } else {
            return res.status(404).json({ Error: "Account not found" });
        }
    });
};


module.exports = {
    getAccount,
    getAllInforAcc,
    updateaccountusername,
    getAccountById
};