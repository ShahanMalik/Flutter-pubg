import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:rive/rive.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flame_rive/flame_rive.dart';

class Fireball extends SpriteComponent {
  vmath.Vector2 velocity;

  Fireball({
    required Sprite sprite,
    required vmath.Vector2 position,
    required this.velocity,
    required vmath.Vector2 size,
  }) : super(sprite: sprite, position: position, size: size);

  @override
  void update(double dt) {
    position += velocity * dt;
    super.update(dt);
  }
}

class MyGame extends FlameGame {
  static final MyGame instance = MyGame();

  late SpriteComponent player;
  late Sprite fireballSprite;
  late Artboard backgroundArtboard;
  late RiveComponent backgroundRiveComponent;
  late Sprite enemySprite;
  vmath.Vector2 playerDirection =
      vmath.Vector2(1, 0); // Default direction to the right
  double playerSpeed = 200; // Adjust player speed as needed
  List<Enemy> enemies = []; // List to hold multiple enemies
  late Timer respawnTimer;

  @override
  Future<void> onLoad() async {
    // Load the Rive file
    final backgroundRiveFile =
        await RiveFile.asset('assets/images/game_battleground.riv');
    backgroundArtboard = backgroundRiveFile.mainArtboard;

    // Verify available animations
    print(
        'Available animations: ${backgroundArtboard.animations.map((a) => a.name).toList()}');

    // Play the first animation on the artboard
    final controller =
        SimpleAnimation('Timeline 1'); // Use 'Timeline 1' or 'State Machine 1'
    backgroundArtboard.addController(controller);

    backgroundRiveComponent = RiveComponent(
      artboard: backgroundArtboard,
      size: Vector2(size.x, size.y), // Fit the background to the game size
    );

    // Add the background Rive component to the game
    add(backgroundRiveComponent);

    // Load player sprite
    final playerSprite = await loadSprite('player.png');
    player = SpriteComponent(
      sprite: playerSprite,
      size: vmath.Vector2(100, 100), // Set the size of the player sprite
      position:
          vmath.Vector2(size.x / 2 - 32, size.y - 100), // Center horizontally
    );
    add(player);

    // Load fireball sprite
    fireballSprite = await loadSprite('fireball.png');

    // Load enemy sprite
    enemySprite = await loadSprite('enemy.png');

    // Set up respawn timer
    // Set up respawn timer to run indefinitely
    respawnTimer = Timer(1, onTick: spawnEnemies, repeat: true);
    respawnTimer.start();

    // Initial enemy spawn
    spawnEnemies();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Ensure the player stays within bounds
    player.position.x = clamp(player.position.x, 0, size.x - player.size.x);
    player.position.y = clamp(player.position.y, 0, size.y - player.size.y);

    // Update the respawn timer
    respawnTimer.update(dt);

    // Update each enemy
    for (final enemy in enemies) {
      enemy.update(dt);
    }

    // Check for collisions between fireballs and enemies
    for (final component in children) {
      if (component is Fireball) {
        for (final enemy in enemies) {
          if (component.toRect().overlaps(enemy.toRect())) {
            // Decrease enemy health on collision and remove fireball
            enemy.takeDamage(1);
            remove(component);
            break;
          }
        }
      } else if (component is EnemyBullet) {
        if (component.toRect().overlaps(player.toRect())) {
          // Handle player getting hit by an enemy bullet
          remove(component);
          // You can add logic here to reduce player health or end the game
        }
      }
    }

    // Remove any enemies that are killed
    enemies.removeWhere((enemy) => enemy.isDead);

    // Check if all enemies are dead and reset the respawn timer if necessary
    if (enemies.isEmpty && !respawnTimer.isRunning()) {
      respawnTimer.start();
    }
  }

  void movePlayer(vmath.Vector2 delta) {
    player.position.add(delta);
    player.position.x = clamp(player.position.x, 0, size.x - player.size.x);
    player.position.y = clamp(player.position.y, 0, size.y - player.size.y);

    if (delta.x != 0) {
      playerDirection = vmath.Vector2(delta.x.sign, 0);
    }
  }

  void shootFireball() {
    final fireball = Fireball(
      sprite: fireballSprite,
      size: vmath.Vector2(5, 5), // Decrease the size of the fireball
      position:
          player.position + vmath.Vector2(94, 14), // Start at player's location
      velocity: vmath.Vector2(playerDirection.x.abs() * 300, 0),
    );
    add(fireball);
  }

  void spawnEnemies() {
    // Spawn a new enemy
    final enemy = Enemy(
      sprite: enemySprite,
      size: vmath.Vector2(64, 64),
      position: vmath.Vector2(
          size.x - 100, size.y / 2 - 50), // Adjust the position if needed
    );
    add(enemy);
    enemies.add(enemy);

    // Adjust the position for subsequent enemies
    if (enemies.length % 2 == 0) {
      enemy.position.y += 100; // Position below the previous one
    }
  }

  double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class Enemy extends SpriteComponent {
  static const double speed = 10;
  int health = 2; // Initialize enemy health
  late Timer shootTimer;
  bool isDead = false; // Flag to mark if the enemy is dead

  Enemy({
    required Sprite sprite,
    required vmath.Vector2 position,
    required vmath.Vector2 size,
  }) : super(sprite: sprite, position: position, size: size) {
    shootTimer = Timer(2, repeat: true, onTick: shootAtPlayer);
    shootTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    shootTimer.update(dt);

    if (isDead) {
      removeFromParent();
      return;
    }

    if (MyGame.instance.player != null) {
      vmath.Vector2 direction = MyGame.instance.player!.position - position;
      if (direction.length2 > 0) {
        direction = direction.normalized();
      }
      // Move the enemy towards the player
      position += direction * speed * dt;

      // Ensure the enemy stays within bounds
      position.x =
          MyGame.instance.clamp(position.x, 0, MyGame.instance.size.x - size.x);
      position.y =
          MyGame.instance.clamp(position.y, 0, MyGame.instance.size.y - size.y);
    }
  }

  void shootAtPlayer() {
    if (MyGame.instance.player != null) {
      vmath.Vector2 direction = MyGame.instance.player!.position - position;
      if (direction.length2 > 0) {
        direction = direction.normalized();
      }
      final bullet = EnemyBullet(
        sprite: MyGame.instance
            .fireballSprite, // You can use a different sprite for enemy bullets
        size: vmath.Vector2(5, 5), // Size of the bullet
        position: position +
            vmath.Vector2(
                size.x / 9, size.y / 6), // Start from the enemy's position
        velocity: direction * 200, // Speed of the bullet
      );
      MyGame.instance.add(bullet);
    }
  }

  void takeDamage(int damage) {
    FlameAudio.play('explosion.mp3');
    health -= damage;
    if (health <= 0) {
      isDead = true;
      removeFromParent(); // Remove enemy from the game
    }
  }
}

class EnemyBullet extends SpriteComponent {
  vmath.Vector2 velocity;

  EnemyBullet({
    required Sprite sprite,
    required vmath.Vector2 position,
    required this.velocity,
    required vmath.Vector2 size,
  }) : super(sprite: sprite, position: position, size: size);

  @override
  void update(double dt) {
    position += velocity * dt;
    super.update(dt);

    // Remove bullet if it goes off-screen
    if (position.x < 0 ||
        position.x > MyGame.instance.size.x ||
        position.y < 0 ||
        position.y > MyGame.instance.size.y) {
      removeFromParent();
    }
  }
}
