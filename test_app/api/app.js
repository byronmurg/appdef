const express = require("express")

const app = express()

app.get(`${process.env.MOUNT_PATH}/foo`, (req, res) => {
	res.json({ "some":"data" })
})

app.listen(process.env.PORT, () => console.log("started"))
