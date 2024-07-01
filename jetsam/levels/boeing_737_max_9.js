let testObject;

const config = {
    type: Phaser.AUTO,
    width: 800,
    height: 600,
    scene: {
        preload: preload,
        create: create,
        update: update
    }
};

let game = new Phaser.Game(config);

function preload() {
    // Load an image for the test object
    this.load.image('testObject', 'path/to/testObject.png');
}

function create() {
    // Add the test object to the scene
    testObject = this.add.image(400, 300, 'testObject');
}

function update() {
    // Rotate the test object
    testObject.angle += 1;
}