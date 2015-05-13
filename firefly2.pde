//For Processing.js
/* @pjs preload="img/background.jpg"; */

final int NUM_FRAMERATE = 30;

final int NUM_PARTICLES = 10;
final int NUM_PARTICLES_BEHIMD = 40;

final int NUM_KITES = 1;

PImage backgroundImg;
ArrayList<Particle> particles;
ArrayList<Kite> kites;

boolean recording = false;


//--------------------------------------------------------------------------------
void setup(){
	setInitWindow();
	setInitParticles();
	setInitKites();
}

void setInitWindow() {
	size(800, 600);
	frameRate(NUM_FRAMERATE);
	backgroundImg = loadImage("img/background.jpg");
	particles = new ArrayList<Particle>();
	kites = new ArrayList<Kite>();
}

void setInitParticles() {
	for (int i = 0; i < NUM_PARTICLES_BEHIMD; i++) {
		particles.add(new ParticleBehind());
	}
	for (int i = 0; i < NUM_PARTICLES; i++) {
		particles.add(new Particle());
	}
}

void setInitKites() {
	for (int i = 0; i < NUM_KITES; i++) {
		kites.add(new Kite());
	}
}


//--------------------------------------------------------------------------------
void draw(){
	tint(192, 128, 255);
	image(backgroundImg, 0, 0);
	noTint();

	for (Particle particle : particles) {
		particle.run();
	}
	for (Kite kite : kites) {
		kite.run();
	}
}

void keyPressed() {
	if (recording == true && key == 'r') {
		saveFrame("output/frame-####.png");
	}
}


//--------------------------------------------------------------------------------
class Particle {
	protected PVector pos;
	protected Moving moving;
	protected Blinking blinking;

	Particle() {
		setPos();
		setMotions();
	}

	protected void setPos() {
		pos = new PVector(random(50, width - 50), random(50, height - 50));
	}
	protected void setMotions() {
		moving = new Moving(pos);
		blinking = new Blinking(pos, (new ParticleImageCreater()).create());
	}

	public void run() {
		move();
		blink();
	}
	private void move() {
		moving.move();
	}
	private void blink() {
		blinking.blink();
	}

}


class ParticleBehind extends Particle {
	ParticleBehind() {
		super();
	}
	protected void setPos() {
		pos = new PVector(random(50, width - 50), random(350, height - 50));
	}
	protected void setMotions() {
		moving = new MovingBehind(pos);
		blinking = new BlinkingBehind(pos, (new ParticleImageCreater()).create());
	}
}


//--------------------------------------------------------------------------------
class Moving {
	private PVector pos;
	private PVector velocityBase;

	private final int MARGIN = -50;

	private float radianPushPull = 0.0;
	private float radianPushPullDelta = 0.075;

	private float radianWave = 0.0;
	private float radianWaveDelta = 0.1;

	Moving(PVector pos) {
		this.pos = pos;
		setInitVelocityBase();
		radianPushPull = random(0, TWO_PI);
		radianWave = random(0, TWO_PI);
	}

	protected float getBehindValue() {
		return 1;
	}
	protected int getMarginTop() {
		return 200;
	}

	private void setInitVelocityBase() {
		velocityBase = new PVector(random(-2.25, 2.25), random(-1.25, 1.25));
		if (velocityBase.x >= 0 && velocityBase.x < 0.5) {
			velocityBase.x = 1.0;
		} else if (velocityBase.x > -0.5 && velocityBase.x < 0) {
			velocityBase.x = -1.0;
		}
		velocityBase.x *= getBehindValue();
		velocityBase.y *= getBehindValue();
	}

	public void move() {
		forward();
		bounce();
	}

	private void forward() {
		PVector velocity = velocityBase.get();
		PVector acceleration = new PVector(0, 0);

		PVector forcePushPull = createForcePushPull(velocity);
		acceleration.add(forcePushPull);

		PVector forceWave = createForceWave(velocity);
		acceleration.add(forceWave);

		velocity.add(acceleration);
		pos.add(velocity);
	}

	private PVector createForcePushPull(PVector velocity) {
		float sinval = sin(radianPushPull);
		float px = velocity.x * sinval * 0.35;
		float py = velocity.y * sinval * 0.35;
		if (radianPushPull >= TWO_PI) {
			radianPushPull = 0.0;
		}else{
			radianPushPull += radianPushPullDelta;
		}
		PVector forcePushPull = new PVector(px, py);
		return forcePushPull;
	}
	private PVector createForceWave(PVector velocity) {
		float radianAngle = atan2(velocity.y, velocity.x);
		float sinval = sin(radianWave);
		float wx = (-1 * sin(radianAngle)) * sinval * 1;
		float wy = cos(radianAngle) * sinval * 1;
		if (radianWave >= TWO_PI) {
			radianWave = 0.0;
		}else{
			radianWave += radianWaveDelta;
		}
		wx *= getBehindValue();
		wy *= getBehindValue();
		PVector forceWave = new PVector(wx, wy);
		return forceWave;
	}

	private void bounce() {
		if (pos.x + MARGIN >= width) {
			velocityBase.x *= -1;
			pos.x = width - MARGIN;
		}
		if (pos.x - MARGIN <= 0) {
			velocityBase.x *= -1;
			pos.x = MARGIN;
		}
		if (pos.y + MARGIN >= height) {
			velocityBase.y *= -1;
			pos.y = height - MARGIN;
		}
		if (pos.y - getMarginTop() <= 0) {
			velocityBase.y *= -1;
			pos.y = getMarginTop();
		}
	}
}


class MovingBehind extends Moving {
	MovingBehind(PVector pos) {
		super(pos);
	}
	protected float getBehindValue() {
		return 0.3;
	}
	protected int getMarginTop() {
		return 350;
	}
}


//--------------------------------------------------------------------------------
class ParticleImageCreater {
	public static final float LIGHT_POWER_MIN = 0;
	public static final float LIGHT_POWER_MAX = 4 * 4;

	private static final int PIXEL_BORDER = 20;
	private static final int LIGHT_DISTANCE= 20 * 20;

	ParticleImageCreater() {
	}

	public PImage create() {
		color baseColor = color(random(50, 100), random(100, 220), random(50, 100));

		int pixelIndex = 0;
		color c;
		float r, g, b, a;
		float dx, dy, distance;

		PVector pos = new PVector(0, 0);
		int left = int(pos.x - PIXEL_BORDER);
		int right = int(pos.x + PIXEL_BORDER);
		int top = int(pos.y - PIXEL_BORDER);
		int bottom = int(pos.y + PIXEL_BORDER);

		int imgWidth = right - left;
		int imgHeight = bottom - top;
		PImage particleImage = createImage(imgWidth, imgHeight, ARGB);

		int imgPixelIndex = 0;
		for (int y = top; y < bottom; y++) {
			for (int x = left; x < right; x++) {
				c = color(0, 0, 0, 0);
				particleImage.pixels[imgPixelIndex] = c;
				r = red(c);
				g = green(c);
				b = blue(c);
				dx = pos.x - x;
				dy = pos.y - y;
				distance = dx * dx + dy * dy;
				if (distance < LIGHT_DISTANCE) {
					r += red(baseColor) * LIGHT_POWER_MAX / distance;
					g += green(baseColor) * LIGHT_POWER_MAX / distance;
					b += blue(baseColor) * LIGHT_POWER_MAX / distance;
					a = map(brightness(color(r, g, b)), 0, 120, 0, 255);
					particleImage.pixels[imgPixelIndex] = color(r, g, b, a);
				}
				imgPixelIndex++;
			}
		}
		return particleImage;
	}
}


//--------------------------------------------------------------------------------
class Blinking {
	private PVector pos;
	private PImage particleImage;

	private float lightPower;
	private float lightPowerDelta;

	private int INIT_INTERVAL_MSEC = 0;
	private int INTERVAL_SLEEP_MSEC = 1500;
	private int INTERVAL_FULLLIGHT_MSEC = 1500;
	private int timeAtSleeped = 0;
	private int timeAtFulllight = 0;

	Blinking(PVector pos, PImage particleImage) {
		this.pos = pos;
		this.particleImage = particleImage;

		lightPower = random(ParticleImageCreater.LIGHT_POWER_MIN, ParticleImageCreater.LIGHT_POWER_MAX);
		lightPowerDelta = 0.4;

		INIT_INTERVAL_MSEC = int(random(0, 10000));
		INTERVAL_SLEEP_MSEC += int(random(0, 1000));
	}

	protected float getBehindValue() {
		return 1;
	}

	private boolean passedInitInterval() {
		int now = millis();
		if (now > INIT_INTERVAL_MSEC) {
			return true;
		}else{
			return false;
		}
	}
	private boolean isTimeOfAwaking() {
		int now = millis();
		if (now - timeAtSleeped > INTERVAL_SLEEP_MSEC) {
			return true;
		}else{
			return false;
		}
	}
	private boolean isTimeOfFadeout() {
		int now = millis();
		if (now - timeAtFulllight > INTERVAL_FULLLIGHT_MSEC) {
			return true;
		}else{
			return false;
		}
	}

	public void blink() {
		if (passedInitInterval() == false) {
			return;
		}
		if (isTimeOfAwaking() == false) {
			return;
		}

		float LIGHT_POWER_MIN = ParticleImageCreater.LIGHT_POWER_MIN;
		float LIGHT_POWER_MAX = ParticleImageCreater.LIGHT_POWER_MAX;

		float scale = map(lightPower, LIGHT_POWER_MIN, LIGHT_POWER_MAX, 0.1, 1);
		scale *= getBehindValue();
		imageMode(CENTER);
		image(particleImage, pos.x, pos.y, particleImage.width * scale, particleImage.height * scale);
		imageMode(CORNER);

		if (isTimeOfFadeout() == false) {
			return;
		}

		lightPower += lightPowerDelta;
		if (lightPower >= LIGHT_POWER_MAX) {
			lightPower = LIGHT_POWER_MAX;
			lightPowerDelta *= -1;
			timeAtFulllight = millis();
		}else if (lightPower < LIGHT_POWER_MIN) {
			lightPower = LIGHT_POWER_MIN;
			lightPowerDelta *= -1;
			timeAtSleeped = millis();
		}
	}
}


class BlinkingBehind extends Blinking {
	BlinkingBehind(PVector pos, PImage particleImage) {
		super(pos, particleImage);
	}
	protected float getBehindValue() {
		return 0.5;
	}
}


//--------------------------------------------------------------------------------
class Kite {
	private PVector POINT_CENTER = new PVector(0, -100);
	private PVector pos;
	private PGraphics kiteShape;

	private final float radiusX = 400.0;
	private final float radiusY = 150.0;
	private float radianCircle = 0.0;
	private float radianCircleDelta = 0.015;

	private int INTERVAL_SLEEP_MSEC = 14000;
	private int timeAtSleeped = 0;

	Kite() {
		setCenterX();
		setPos();
		createKiteShape();
	}

	private void setCenterX() {
		POINT_CENTER.x = random(0, width);
	}

	private void setPos() {
		pos = new PVector(0, 0);
	}

	private void createKiteShape() {
		kiteShape = createGraphics(50, 110);
		kiteShape.beginDraw();
		kiteShape.beginShape();
		kiteShape.fill(0);
		kiteShape.noStroke();

		kiteShape.vertex(40, 0);
		kiteShape.vertex(50, 20);

		kiteShape.vertex(40, 50);
		kiteShape.vertex(50, 55);
		kiteShape.vertex(40, 60);

		kiteShape.vertex(50, 90);
		kiteShape.vertex(40, 110);

		kiteShape.vertex(30, 80);
		kiteShape.vertex(20, 60);

		kiteShape.vertex(0, 65);
		kiteShape.vertex(0, 45);

		kiteShape.vertex(20, 50);
		kiteShape.vertex(30, 30);
		kiteShape.vertex(40, 0);

		kiteShape.endShape(CLOSE);
		kiteShape.endDraw();
	}

	private boolean isTimeOfAwaking() {
		int now = millis();
		if (now - timeAtSleeped > INTERVAL_SLEEP_MSEC) {
			return true;
		}else{
			return false;
		}
	}

	public void run() {
		if (isTimeOfAwaking() == false) {
			return;
		}
		move();
	}

	private void move() {
		update();
		display();
	}
	private void update() {
		float sinval = sin(radianCircle) * -1;
		float cosval = cos(radianCircle);
		pos.x = POINT_CENTER.x + cosval * radiusX;
		pos.y = POINT_CENTER.y + sinval * radiusY;
		if (radianCircle >= TWO_PI) {
			radianCircle = 0.0;
			setCenterX();
			timeAtSleeped = millis();
		}else{
			radianCircle += radianCircleDelta;
		}
	}
	private void display() {
		pushMatrix();
		translate(pos.x, pos.y);
		rotate( (HALF_PI + radianCircle) * -1);

		float scale = 0.25;
		imageMode(CENTER);
		image(kiteShape, 0, 0, kiteShape.width * scale, kiteShape.height * scale);
		imageMode(CORNER);

		popMatrix();
	}
}


//--------------------------------------------------------------------------------
