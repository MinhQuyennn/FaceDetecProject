const positionController = require('../controller/positionController');
const express = require("express");
const router = express.Router();

router.get("/getPosition", positionController.getAllPositions);
router.post('/createpositions', positionController.insertPosition);
router.put('/updatepositions/:id', positionController.updatePosition);
router.delete('/delpositions/:id', positionController.deletePosition);

module.exports = router;