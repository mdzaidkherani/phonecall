const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

let rooms = {}; // Store offers, answers, and candidates for each room

// Create an offer
app.post("/create-room", (req, res) => {
    console.log("Offer received:", req.body);
    const { sdp, type } = req.body;
    const roomId = Date.now().toString();
    rooms[roomId] = { offer: { sdp, type }, answer: null, candidates: [] };
    res.json({ roomId });
});

// Get offer by room ID
app.get("/room/:roomId", (req, res) => {
    console.log(req.params.roomId);
    console.log('room/roomId');
    const room = rooms[req.params.roomId];
    res.json(room || {});
});

// Post an answer
app.post("/room/:roomId/answer", (req, res) => {
    console.log(`Answer received for Room ${req.params.roomId}:`, req.body);
    if (!rooms[req.params.roomId]) {
        return res.status(404).json({ error: "Room not found" });
    }
    rooms[req.params.roomId].answer = req.body;
    res.json({ success: true });
});

// Post ICE candidates
app.post("/room/:roomId/candidate", (req, res) => {
    console.log(`ICE Candidate for Room ${req.params.roomId}:`, req.body);
    if (!rooms[req.params.roomId]) {
        return res.status(404).json({ error: "Room not found" });
    }
    rooms[req.params.roomId].candidates.push(req.body);
    res.json({ success: true });
});

// Get ICE candidates
app.get("/room/:roomId/candidates", (req, res) => {
    console.log(req.params.roomId);
    console.log(req.body);
    console.log('room/roomId/candidates');
    const room = rooms[req.params.roomId];
    res.json(room ? room.candidates : []);
});

// Start server
app.listen(3000, () => console.log("Signaling server running on port 3000"));

