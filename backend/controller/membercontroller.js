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

module.exports = { 
    createMember 
};