# Installing Nargo (Noir Toolchain)

You've already installed `noirup`, now you need to complete the installation:

## Step 1: Source your bashrc
```bash
source ~/.bashrc
```

## Step 2: Install Nargo
```bash
noirup
```

This will download and install the latest version of Nargo (the Noir compiler and test runner).

## Step 3: Verify Installation
```bash
nargo --version
```

## Step 4: Run All Tests
Once nargo is installed, you can run the full test suite:
```bash
./scripts/test_all.sh
```

This will run:
1. Noir circuit tests (commitment, merkle, withdraw)
2. Soroban contract unit tests
3. Soroban contract integration tests

---

## Alternative: Install Specific Version

If you need a specific version of Nargo:
```bash
noirup --version <version>
```

For example:
```bash
noirup --version 0.34.0
```

## Troubleshooting

If `nargo` is still not found after installation:
1. Check if it's in your PATH: `echo $PATH | grep .nargo`
2. Manually add to PATH: `export PATH="$HOME/.nargo/bin:$PATH"`
3. Restart your terminal session
