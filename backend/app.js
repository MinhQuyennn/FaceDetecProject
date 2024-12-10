const express = require("express");



const accountRoutes = require("./routes/accounts");
const authRoutes = require("./routes/auth");
const positionRoutes = require("./routes/position");
const memberRoutes = require("./routes/member");
const regisImageRoutes = require("./routes/regisImage"); // Ensure this file exists

require("dotenv").config();

const cors = require("cors");
const mysql = require("mysql2");
const bodyParser = require("body-parser");
const path = require("path");

const db = require("./config/database");
const configViewEngine = require("./config/viewEngine");
const app = express();

const port = process.env.PORT;

app.use(cors());
configViewEngine(app);



app.use(express.json({ limit: "50mb" })); // Set payload size limit
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));


app.use("/", accountRoutes);
app.use("/", authRoutes);
app.use("/", positionRoutes);
app.use("/", memberRoutes);
app.use("/", regisImageRoutes); // This must point to the correct route file

// Middleware for serving static files
app.use("/uploads", express.static(path.join(__dirname, "public/uploads")));

// Catch-all middleware for unknown routes
app.use((req, res) => {
  res.status(404).send(`Route ${req.method} ${req.originalUrl} not found.`);
});

// Start the server
app.listen(port, "0.0.0.0", () => {
  console.log(`Server is running on port ${port}`);
});

// Check the MySQL connection
db.query("SELECT 1 + 1", (error, results, fields) => {
  if (error) {
    console.error("Error connecting to MySQL:", error.message);
    return;
  }
  console.log("Connected to MySQL!");
});