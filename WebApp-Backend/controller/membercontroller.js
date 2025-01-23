const db = require("../config/database");
const express = require("express");

// Controller to create a new member
const createMember = async (req, res) => {
    const { account_id, name, position_id, address, phone_number, email } = req.body;

    if (!name || !position_id) {
        return res.status(400).json({ success: false, message: 'Name and position_id are required.' });
    }

    try {
        const [result] = await db.promise().query(
            `INSERT INTO tbl_member (account_id, name, position_id, address, phone_number, email) VALUES (?, ?, ?, ?, ?, ?)`,
            [account_id, name, position_id, address, phone_number, email]
        );
        res.status(201).json({ success: true, message: 'Member created successfully.', member_id: result.insertId });
    } catch (error) {
        console.error('Error creating member:', error);
        if (error.code === 'ER_NO_REFERENCED_ROW_2') {
            return res.status(400).json({ success: false, message: 'Invalid account_id or position_id.' });
        }
        res.status(500).json({ success: false, message: 'An error occurred while creating the member.' });
    }
};

const updateMember = async (req, res) => {
    const memberId = req.params.id; // Get the member ID from the URL parameters
    const { name, position_id, address, phone_number, email } = req.body; // Extract values from the request body

    // Start building the SQL query dynamically
    let sql = "UPDATE tbl_member SET";
    let values = [];
    let updateFields = []; // Array to track update fields

    if (name) {
        updateFields.push("name = ?");
        values.push(name);
    }
    if (position_id) {
        updateFields.push("position_id = ?");
        values.push(position_id);
    }
    if (address) {
        updateFields.push("address = ?");
        values.push(address);
    }
    if (phone_number) {
        updateFields.push("phone_number = ?");
        values.push(phone_number);
    }
    if (email) {
        updateFields.push("email = ?");
        values.push(email);
    }

    // If no fields to update, return an error response
    if (updateFields.length === 0) {
        return res.status(400).json({ Error: "No fields to update" });
    }

    // Construct the SQL query dynamically
    sql += ` ${updateFields.join(", ")} WHERE id = ?`;
    values.push(memberId); // Add member ID for the WHERE clause

    // Execute the query
    db.query(sql, values, (err, result) => {
        if (err) {
            console.error("Error updating member:", err);
            return res.status(500).json({ Error: "Internal server error" });
        }

        // Check if the member was updated (affected rows > 0)
        if (result.affectedRows > 0) {
            return res.status(200).json({ Status: "Member updated successfully" });
        } else {
            return res.status(404).json({ Error: "Member not found" });
        }
    });
};
 


module.exports = { 
    createMember,
    updateMember
};