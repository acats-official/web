var world, Bodies, Composite
var image = new Image();
image.src = 'img/misc/tinto.svg';
var imageWidth = 200;
var imageHeight = 700;

var canvas_div = document.getElementById('bottles')
var width = canvas_div.clientWidth;
var height = canvas_div.clientHeight;

function spawn_bottles() {
    var rnd_off =Math.floor(Math.random() * width)
    var imageBody = Bodies.rectangle(rnd_off, height-400, imageWidth/4-5, imageHeight/4+5, {
        render: {
            fillStyle: 'red',
            sprite: {
            texture: image.src,
                xScale: 1.2,
                yScale: 1.2
        }
        }
    });

    Matter.Body.rotate(imageBody, rnd_off)


    Composite.add(world, [imageBody]);
}

function setup_bottles(amount) {


    var Engine = Matter.Engine,
        Render = Matter.Render,
        Runner = Matter.Runner,
        MouseConstraint = Matter.MouseConstraint,
        Mouse = Matter.Mouse,
        Svg = Matter.Svg,
        World = Matter.World;

    Composite = Matter.Composite,
    Bodies = Matter.Bodies


    var engine = Engine.create();
    world = engine.world
    world.gravity.y = 2;



    var render = Render.create({
        element: canvas_div,
        options: {
            width: width,
            height: height,
            background: 'transparent',
            wireframes: false 
        },
        engine: engine
    });

    Render.lookAt(render, {
        min: { x: 0, y: 0 },
        max: { x: width, y: height }
    });

    // add mouse control
    var mouse = Mouse.create(render.canvas),
        mouseConstraint = MouseConstraint.create(engine, {
            mouse: mouse,
            constraint: {
                stiffness: .1,
                render: {
                    visible: false
                }
            }
        });

    function mouse_scroll_fixes(){
        mouse.mousedown = function(event) {
            var position = Mouse._getRelativeMousePosition(event, mouse.element, mouse.pixelRatio),
                touches = event.changedTouches;

            if (touches) {
                mouse.button = 0;
                event.preventDefault();
            } else {
                mouse.button = event.button;
            }

            mouse.absolute.x = position.x;
            mouse.absolute.y = position.y;
            mouse.position.x = mouse.absolute.x * mouse.scale.x + mouse.offset.x;
            mouse.position.y = mouse.absolute.y * mouse.scale.y + mouse.offset.y;
            mouse.mousedownPosition.x = mouse.position.x;
            mouse.mousedownPosition.y = mouse.position.y;
            mouse.sourceEvents.mousedown = event;
        };
        mouseConstraint.mouse.element.removeEventListener("mousewheel", mouseConstraint.mouse.mousewheel);
        mouseConstraint.mouse.element.removeEventListener("DOMMouseScroll", mouseConstraint.mouse.mousewheel);
    }
    mouse_scroll_fixes()

    Composite.add(world, mouseConstraint);

    // keep the mouse in sync with rendering
    render.mouse = mouse;

    // start_x, start_y, width, height
    // Top left is 0,0

    var start_x = 0
    var start_y = 0
    var wall_width = 300
    var show_walls = true
    Composite.add(world, [
        Bodies.rectangle(start_x, start_y+wall_width/2-wall_width, width*2, wall_width, { isStatic: true,  render: { visible: show_walls} } ), // top
        Bodies.rectangle(start_x+wall_width/2-wall_width, start_y, wall_width, height*2, { isStatic: true,  render: { visible: show_walls} }), // left
        Bodies.rectangle(width-wall_width/2+wall_width, start_y, wall_width, height*2, { isStatic: true,  render: { visible: show_walls} }),// right
        Bodies.rectangle(start_x, height-wall_width/2+wall_width, width*2, wall_width, { isStatic: true,  render: { visible: show_walls} }), // bottom
    ]);



    for (let i = 0; i < amount; i++) {
        var rnd_off =Math.floor(Math.random() * 50)
        var imageBody = Bodies.rectangle(width-100-i*70+rnd_off, height-100, imageWidth/4-5, imageHeight/4+5, {
            render: {
                fillStyle: 'red',
                sprite: {
                texture: image.src,
                    xScale: 1.2,
                    yScale: 1.2
            }
            }
        });

        Composite.add(world, [imageBody]);
    }


    Render.run(render);
    var runner = Runner.create();
    Runner.run(runner, engine);

}

const viewportWidth = window.innerWidth;

if (window.matchMedia("(min-width: 1300px)").matches) {
    emit("easter_egg", {'type':'bottles'})
    setup_bottles((window.innerWidth - 1050) / 150)
}
