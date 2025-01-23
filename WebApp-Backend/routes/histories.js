const historiesController = require('../controller/historiesController');
const express = require("express");
const router = express.Router();

router.post('/createhistories', historiesController.createEnterHistory);
router.delete('/deletehistories/:id', historiesController.deleteHistories);
router.get('/getAllHistories', historiesController.getAllHistories);
router.get('/getHistoriesByMemberId/:id', historiesController.getHistoriesByMemberId);

module.exports = router; 