# easyclaw

A simplified setup for running OpenClaw with Docker and Discord.

## Included

* Image: ghcr.io/openclaw/openclaw:latest
* Easy script: `claw [init|config|log|start|stop|restart|build|update|run|dashboard]`
* OpenClaw running inside a container, isolated from the host system
* ~/.openclaw folder mounted on the host, so you can access easily, and assets persist across runs
* Dashboard accessible from outside the container
* Chromium browser inside the container for agent
* MarkItDown MCP for agents to convert various files to markdown
* Playwright for Node.js
* UV for Python
* FFmpeg

## Prerequisites

- **Docker** and **Docker Compose**
- **Python 3.11+** (for configuration generation)

## Discord Bot Setup

To use OpenClaw with Discord, you need to create a Discord bot and obtain a token and server ID. Follow these steps based on the [OpenClaw documentation](https://docs.openclaw.ai/channels/discord):

### 1. Get a Discord Server
If you don't already have a server for your bot:
- Open Discord and click the **+** (Add a Server) button.
- Choose **Create My Own** > **For me and my friends**.
- **Enable Developer Mode:** Go to **User Settings** (gear icon) > **Advanced** and toggle on **Developer Mode**. This is required to copy IDs.
- Right-click your server's icon in the left sidebar.
- Click **Copy Server ID** and make a note.

### 2. Create a Discord Bot
- Go to the [Discord Developer Portal](https://discord.com/developers/applications).
- Click **New Application** and give it a name (e.g., "OpenClaw").
- In the left sidebar, click **Bot**.
- **Enable Privileged Gateway Intents:** Scroll down to the "Privileged Gateway Intents" section and toggle **ON**:
    - **Message Content Intent** (Required)
    - **Server Members Intent** (Recommended)

### 3. Obtain the Bot Token
- On the **Bot** page, find the "Token" section.
- Click **Reset Token** (or "Copy" if visible) to get your token.
- **Save this token immediately.** It is a secret and will not be shown again. This is your `DISCORD_BOT_TOKEN`.

### 5. Add the Bot to Your Server
- In the Developer Portal, go to **OAuth2** > **URL Generator**.
- Under **Scopes**, select `bot` and `applications.commands`.
- Under **Bot Permissions**, select `View Channels`, `Send Messages`, `Read Message History`, `Embed Links`, and `Attach Files`.
- Copy the generated URL at the bottom, paste it into your browser, select your server, and authorize the bot.

## Openclaw Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/chigkim/easyclaw
   cd easyclaw

   # On Linux/macOS, make the script executable:
   chmod +x claw.sh
   ```

2. **Configure the application:**
   Copy claw-example.toml to claw.toml and edit claw.toml with your setup.

   Edit `claw.toml` to include:
   - Your LLM provider and model details for OpenAI compatible API.
   - Your Discord Bot token and Server ID.

3. **Initialize the project:**
   This command will generate the final configuration, set up the necessary directories, and start the Docker containers.
   ```bash
   # On Linux/macOS
   ./claw.sh init

   # On Windows
   claw.bat init
   ```

## Usage

The claw script provide several commands to manage your instance:

- `init`: Full initialization (generates config from claw.toml, recreates directories, builds and starts containers).
- `start`: Start existing containers.
- `stop`: Stop running containers.
- `restart`: Restart containers.
- `log`: View real-time logs.
- `config`: Re-generate the `openclaw.json` configuration from `claw.toml` without restarting everything.
- `build`: Re-build and start containers.
- `update`: Pull latest images and update containers.
- `dashboard`: Show the OpenClaw dashboard URL.
- `run <command>`: Execute a command inside the running container.

To access your dashboard, you would need to

1. Open the url from the dashboard command.
2. Approve your device with: `./claw.sh run openclaw devices approve --latest`