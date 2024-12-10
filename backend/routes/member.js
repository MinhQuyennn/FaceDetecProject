const MemberController = require('../controller/membercontroller');
const express = require("express");
const router = express.Router();

router.post('/createmembers', MemberController.createMember);


module.exports = router;