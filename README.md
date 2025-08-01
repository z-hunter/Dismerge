# 🎮 Dismerge

A merge-2 puzzle game built with the Defold engine. Players drag and drop tokens to merge them and create higher-level pieces.

## 🎯 Game Features

- **Merge Mechanics**: Combine tokens of the same level to create higher-level pieces
- **Drag & Drop**: Intuitive touch/mouse controls for token manipulation
- **5 Token Levels**: Progress from level 1 to level 5 tokens
- **7x9 Grid**: Strategic gameplay on a spacious game board
- **Smooth Animations**: Fluid token movement and visual feedback

## 🏗️ Architecture

Built using Entity-Component-System (ECS) pattern with centralized game management:

- **Board**: Central game controller managing all game logic
- **Cell**: Static grid elements providing click targets
- **Token**: Interactive game pieces with levels and states

## 🚀 Getting Started

### Prerequisites
- [Defold Engine](https://defold.com/download/) (latest version)

### Installation
1. Clone this repository
2. Open the project in Defold Editor
3. Build and run the game

## 🎨 Visual Design

- **Color-coded tokens**: Each level has a distinct color
- **Dynamic scaling**: Tokens scale based on level and drag state
- **Smooth transitions**: 2500 pixels/second movement speed

## 📁 Project Structure

```
Dismerge/
├── main/           # Game objects and factories
├── scripts/        # Game logic scripts
├── assets/         # Textures and atlases
├── input/          # Input bindings
└── debugger/       # Debug utilities
```

## 🔧 Technical Details

- **Engine**: Defold 2.x
- **Language**: Lua
- **Pattern**: Entity-Component-System
- **Input**: Mouse/Touch with drag & drop

## 📖 Documentation

See [tech-spec.md](tech-spec.md) for detailed technical specifications and architecture documentation.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

Happy merging! 🎮