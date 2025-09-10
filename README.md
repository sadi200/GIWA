Got it! Here’s a clean version you can put directly into a **GitHub `README.md`** with proper formatting for a shell command section:

````markdown
## Setup and Usage

Clone the repository:

```sh
git clone https://github.com/sadi200/GIWA.git
cd GIWA
````

Install dependencies:

```sh
pnpm add dotenv
pnpm add viem@latest
rm -rf node_modules pnpm-lock.yaml
pnpm install
pnpm add -D tsx @types/node
pnpm add viem
```

Set your test private key:

```sh
export TEST_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
```

Run deposit and withdraw scripts:

```sh
node --import=tsx src/deposit_eth.ts
node --import=tsx src/withdraw_eth.ts
```

> **Note:** Replace `0xYOUR_PRIVATE_KEY_HERE` with your actual private key. Make sure `pnpm` is installed globally.

```

This is **ready to paste into a README.md**. It will display properly on GitHub with syntax highlighting for shell commands.  

If you want, I can also make it **look more “user-friendly”** with sections, badges, and step numbers like a professional project README. Do you want me to do that?
```
