const db = require("../config/database");
const express = require("express");
 
const getAllPositions = async (req, res) => {
    try {
        const [rows] = await db.promise().query('SELECT * FROM tbl_position');
        res.status(200).json({
            success: true,
            data: rows  
        });  
    } catch (error) {
        console.error('Error fetching positions:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while fetching positions.'
        });
    }
}; 

const insertPosition = async (req, res) => {
    try {
        const { name } = req.body;

        if (!name) {
            return res.status(400).json({
                success: false,
                message: 'Name is required',
            });
        }

        const [result] = await db.promise().query('INSERT INTO tbl_position (name) VALUES (?)', [name]);
        res.status(201).json({
            success: true,
            message: 'Position created successfully',
            id: result.insertId,
        });
    } catch (error) {
        console.error('Error inserting position:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while creating the position.',
        });
    }
};

// Update an existing position
const updatePosition = async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;

        if (!name) {
            return res.status(400).json({
                success: false,
                message: 'Name is required',
            });
        }

        const [result] = await db.promise().query('UPDATE tbl_position SET name = ? WHERE id = ?', [name, id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Position not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Position updated successfully',
        });
    } catch (error) {
        console.error('Error updating position:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while updating the position.',
        });
    }
};

// Delete a position
const deletePosition = async (req, res) => {
    try {
        const { id } = req.params;

        const [result] = await db.promise().query('DELETE FROM tbl_position WHERE id = ?', [id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Position not found',
            });
        }

        res.status(200).json({
            success: true,
            message: 'Position deleted successfully',
        });
    } catch (error) {
        console.error('Error deleting position:', error);
        res.status(500).json({
            success: false,
            message: 'An error occurred while deleting the position.',
        });
    }
};



module.exports = { 
    getAllPositions,
    insertPosition,
    updatePosition,
    deletePosition
};