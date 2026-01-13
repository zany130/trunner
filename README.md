# KRunner LLM Plugin

A KRunner plugin for KDE Plasma 6 that allows you to query Large Language Models directly from KRunner.

## Features

- 🚀 Query LLMs directly from KRunner
- 🤖 Support for multiple LLM providers:
  - OpenAI (GPT-4, GPT-3.5-turbo, etc.)
  - Anthropic (Claude 3.5 Sonnet, etc.)
  - OpenRouter (various models)
  - Gemini (gemini-2.5-flash, etc.)
  - Groq (allam-2-7b, etc.)
- 📋 Copy responses to clipboard with a single click
- ⚙️ Configurable
- 🔒 Secure API key storage
- ⏱️ Configurable timeout and token limits
- 🎯 Keyword-based triggering to avoid accidental queries

## Requirements

- KDE Plasma 6
- Qt 6.6.0 or later
- KF6 (KDE Frameworks 6)
- CMake 3.28 or later
- C++23 compatible compiler (GCC 14+, Clang 17+)

## Building

### Install Dependencies

On Arch Linux:

```bash
sudo pacman -S \
    extra-cmake-modules \
    qt6-base \
    qt6-tools \
    qt6-networkauth \
    kf6-runner \
    kf6-i18n \
    kf6-config \
    kf6-kcmutils
```

On Ubuntu/Debian:

```bash
sudo apt install \
    extra-cmake-modules \
    qt6-base-dev \
    qt6-base-dev-tools \
    libkf6runner-dev \
    libkf6i18n-dev \
    libkf6config-dev \
    libkf6configwidgets-dev \
    libkf6kcmutils-dev
```

On Fedora:

```bash
sudo dnf install \
    extra-cmake-modules \
    qt6-qtbase-devel \
    kf6-kcmutils-devel \
    kf6-kconfig-devel \
    kf6-kconfigwidgets-devel \
    kf6-ki18n-devel \
    kf6-krunner-devel
```

### Compile and Install

The installation script automatically detects your system type and chooses the appropriate installation method.

#### Automatic Installation (Recommended)

```bash
chmod u+x ./install.sh && ./install.sh --auto-install
```

The script will:
- Detect if your system is immutable (like Fedora Silverblue, Bazzite, etc.)
- Automatically use user-level installation on immutable systems
- Use system-level installation on traditional systems (if you have permissions)

#### Manual Installation Options

**For traditional (mutable) systems:**
```bash
chmod u+x ./install.sh && ./install.sh
cd build && sudo make install
```

**For immutable systems (Fedora Silverblue, Bazzite, etc.):**
```bash
chmod u+x ./install.sh && ./install.sh --user --auto-install
```

Or build and install separately:
```bash
chmod u+x ./install.sh && ./install.sh --user
cd build && make install
```

**Force user-level installation (no sudo required):**
```bash
./install.sh --user --auto-install
```

This installs the plugin to:
- Plugin: `~/.local/lib/qt6/plugins/kf6/krunner/`
- Metadata: `~/.local/share/krunner/dbusplugins/`
- KCM module: `~/.local/lib/qt6/plugins/`

#### Verifying Installation

After installation, verify the plugin is installed:

```bash
# Check if the plugin file exists
ls ~/.local/lib/qt6/plugins/kf6/krunner/krunner_llm.so
# OR for system installation
ls /usr/lib/qt6/plugins/kf6/krunner/krunner_llm.so

# Check if the desktop file exists
ls ~/.local/share/krunner/dbusplugins/plasma-runner-llm.desktop
# OR for system installation
ls /usr/share/krunner/dbusplugins/plasma-runner-llm.desktop
```

**Note:** The exact paths may vary depending on your distribution. On some systems, the plugin directory might be `/usr/lib64/` instead of `/usr/lib/`.

### Restart KRunner

After installation, restart KRunner to load the plugin:

```bash
kquitapp6 krunner
krunner &
```

**For user-level installations**, you may also need to rebuild the system configuration cache:

```bash
kbuildsycoca6 --noincremental
kquitapp6 krunner
krunner &
```

## Configuration

1. Open KDE System Settings
2. Navigate to Search → KRunner → LLM Runner (or search for "LLM Runner Configuration")
3. Configure the following settings:
   - **Trigger Word**: The keyword to activate the plugin (default: "llm")
   - **Provider**: Choose your LLM provider (OpenAI, Anthropic, or OpenRouter)
   - **API Key**: Your API key from the provider
   - **Model**: The specific model to use (e.g., gpt-4, claude-3-5-sonnet-20241022)
   - **Max Tokens**: Maximum length of the response (default: 150)
   - **Timeout**: Request timeout in seconds (default: 30)
   - **Debounce Delay**: The delay from last keystroke after which query is sent to LLM

### Getting API Keys

- **OpenAI**: [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- **Anthropic**: [https://console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
- **OpenRouter**: [https://openrouter.ai/keys](https://openrouter.ai/keys)
- **Gemini**: [https://developers.generativeai.google/products/gemini](https://developers.generativeai.google/products/gemini)
- **Groq**: [https://platform.groq.ai/account/api-keys](https://platform.groq.ai/account/api-keys)

## Usage

1. Open KRunner
2. Type your trigger word followed by your question:
   ```
   llm what is the capital of France?
   llm explain quantum computing in simple terms
   llm write a haiku about programming
   ```
3. The plugin will query the LLM and display the response
4. Click on the result to copy it to your clipboard

## Testing

The project includes comprehensive unit tests:

```bash
cd build
ctest --output-on-failure
```

Or run specific tests:

```bash
./tests/test_llmclient
./tests/test_llmrunner
```

## Troubleshooting

### Plugin doesn't appear in KRunner

1. Verify installation:

   ```bash
   qdbus org.kde.krunner /App org.kde.krunner.App.display
   ```

2. Check if the plugin is loaded:

   ```bash
   kreadconfig6 --file krunnerrc --group Plugins --key llmrunnerEnabled
   ```

3. Enable the plugin manually:
   ```bash
   kwriteconfig6 --file krunnerrc --group Plugins --key llmrunnerEnabled true
   kquitapp6 krunner && krunner &
   ```

4. For user-level installations, ensure the plugin files are in the correct location:
   ```bash
   # Check plugin library
   ls -la ~/.local/lib/qt6/plugins/kf6/krunner/krunner_llm.so
   
   # Check metadata file
   ls -la ~/.local/share/krunner/dbusplugins/plasma-runner-llm.desktop
   ```

### Installation on Immutable Systems

If you're using an immutable Linux distribution (Fedora Silverblue, Bazzite, etc.):

1. **Always use user-level installation:**
   ```bash
   ./install.sh --user --auto-install
   ```

2. **The plugin cannot be installed to system directories** because the root filesystem is read-only.

3. **Verify user-level installation:**
   ```bash
   # Plugin should be here
   find ~/.local -name "krunner_llm.so"
   
   # Metadata should be here
   find ~/.local -name "plasma-runner-llm.desktop"
   ```

4. **If KRunner doesn't detect the plugin**, try restarting your session or running:
   ```bash
   kbuildsycoca6 --noincremental
   kquitapp6 krunner && krunner &
   ```

### API Key Issues

- Verify your API key is correct in the configuration
- Check that you have sufficient credits/quota with your provider
- Some providers require payment method setup even for API access

### Network Errors

- Check your internet connection
- Verify firewall settings allow outbound HTTPS connections
- Some corporate networks block API endpoints - try from a different network

### Build Errors

If you encounter C++23 errors:

- Ensure you're using GCC 14+ or Clang 17+
- Check that CMake 3.28+ is installed
- Try enabling verbose output: `make VERBOSE=1`

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Privacy & Security

- API keys are stored in KDE's configuration system
- No data is logged or stored locally beyond configuration
- All communication with LLM providers uses HTTPS
- The plugin only sends data when explicitly triggered by the user

## Credits

- Built for KDE Plasma 6
- Uses Qt 6 and KDE Frameworks 6
- Inspired by the need for quick AI assistance while coding

## Roadmap

- [ ] Support for local LLM providers (Ollama, etc.)
- [ ] Add streaming response support
- [ ] Implement conversation history
- [ ] Custom system prompts
- [ ] Response formatting options
- [ ] Multi-language support

---

Made with ❤️ for the KDE community
