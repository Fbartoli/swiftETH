# Contributing to swiftETH

Thank you for your interest in contributing to swiftETH! This guide will help you get started.

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/swiftETH.git
   cd swiftETH
   ```

2. **Install dependencies**
   ```bash
   swift package resolve
   ```

3. **Build the project**
   ```bash
   swift build
   ```

4. **Run tests**
   ```bash
   swift test
   ```

## Development Workflow

### 1. Before Starting Work

- Check existing issues or create a new one
- Discuss major changes before implementing
- Review the `.cursorrules` file for coding standards
- Read `ARCHITECTURE.md` to understand the design

### 2. Making Changes

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write tests first** (TDD approach)
   - Add unit tests in `Tests/swiftETHTests/`
   - Ensure tests fail initially
   - Implement feature to make tests pass

3. **Follow coding standards**
   - Check `.cursorrules` for guidelines
   - Match oxlib.sh API design when applicable
   - Keep functions focused and composable
   - Add documentation comments

4. **Test your changes**
   ```bash
   # Run all tests
   swift test
   
   # Run specific test suite
   swift test --filter RPCClientTests
   
   # Check for warnings
   swift build 2>&1 | grep warning
   ```

5. **Update documentation**
   - Add inline documentation for public APIs
   - Update README.md if needed
   - Update TESTING.md for new tests
   - Add entry to CHANGELOG.md

### 3. Committing Changes

**Commit Message Format**:
```
<type>: <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `chore`: Build or tooling changes

**Example**:
```
feat: add EIP-712 typed data signing

Implemented EIP-712 structured data hashing and signing.
Added TypedData struct and domain separator calculation.

Closes #42
```

**Sign your commits**:
```bash
# Configure git to sign commits
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID

# Commit with signature
git commit -S -m "feat: your feature"
```

### 4. Submitting a Pull Request

1. **Push your branch**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request**
   - Go to GitHub and create a PR
   - Fill out the PR template
   - Link related issues
   - Request review

3. **PR Checklist**
   - [ ] All tests pass
   - [ ] No compiler warnings
   - [ ] Code follows `.cursorrules` guidelines
   - [ ] Documentation updated
   - [ ] CHANGELOG.md updated
   - [ ] Commits are signed

4. **CI Checks**
   - Tests must pass on CI
   - No warnings allowed
   - Code coverage should not decrease

## Testing Guidelines

### Unit Tests
- Fast, isolated, no network
- Test individual components
- Use test vectors from specs
- Mock external dependencies

### Integration Tests
- Test with real Ethereum network
- Use public RPC endpoints
- May be slower (network latency)
- Verify against blockchain data

### Test Organization
```swift
// Good test structure
func testFeatureScenario() throws {
    // Arrange
    let input = "test"
    
    // Act
    let result = try someFunction(input)
    
    // Assert
    XCTAssertEqual(result, expectedOutput)
}
```

## Code Review Process

1. **Automated Checks**
   - CI tests must pass
   - No warnings or errors
   - Code coverage maintained

2. **Manual Review**
   - Code quality and style
   - Architecture alignment
   - Security considerations
   - Test coverage

3. **Feedback**
   - Address reviewer comments
   - Update PR as needed
   - Re-request review

4. **Approval & Merge**
   - Requires 1+ approvals
   - Squash merge preferred
   - Delete branch after merge

## Security

### Reporting Security Issues
- **Do not** open public issues for security vulnerabilities
- Email security concerns privately
- Include detailed description and reproduction steps

### Security Guidelines
- Never log private keys or sensitive data
- Use cryptographically secure random generation
- Validate all inputs
- Follow best practices for crypto operations
- Keep dependencies updated

## Adding New Features

### Feature Checklist

1. **Design Phase**
   - [ ] Check oxlib.sh for similar functionality
   - [ ] Design Swift-native API
   - [ ] Document API in issue/proposal
   - [ ] Get feedback from maintainers

2. **Implementation Phase**
   - [ ] Write tests first (TDD)
   - [ ] Implement minimum viable feature
   - [ ] Add inline documentation
   - [ ] Update README with examples

3. **Validation Phase**
   - [ ] All tests pass
   - [ ] No warnings
   - [ ] Performance acceptable
   - [ ] Security reviewed

4. **Documentation Phase**
   - [ ] API documentation complete
   - [ ] Usage examples provided
   - [ ] TESTING.md updated
   - [ ] CHANGELOG.md entry added

## Common Tasks

### Adding a New RPC Method

1. Review Ethereum JSON-RPC spec
2. Add method to `RPCClient.swift`
3. Create type-safe wrapper
4. Add unit test
5. Add integration test
6. Document in README

**Example**:
```swift
// In RPCClient.swift
public func getBlockByNumber(_ blockNumber: UInt64) async throws -> Block {
    let hex = String(format: "0x%x", blockNumber)
    let result: [String: Any] = try await call(
        method: "eth_getBlockByNumber",
        params: [hex, false]
    )
    return try Block(from: result)
}

// In RPCClientTests.swift
func testGetBlockByNumber() async throws {
    let block = try await rpcClient.getBlockByNumber(15_000_000)
    XCTAssertEqual(block.number, 15_000_000)
}
```

### Adding a New Transaction Type

1. Define transaction structure
2. Implement RLP encoding
3. Add signing logic
4. Create comprehensive tests
5. Add usage examples

### Updating Dependencies

1. Check for security updates
2. Review changelog
3. Update `Package.swift`
4. Run full test suite
5. Update documentation if needed

## Resources

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [oxlib.sh Documentation](https://oxlib.sh/)
- [Ethereum Improvement Proposals](https://eips.ethereum.org/)
- [Project Architecture](ARCHITECTURE.md)
- [Testing Guide](TESTING.md)

## Questions?

- Open a discussion on GitHub
- Check existing issues and PRs
- Review `.cursorrules` for guidelines
- Read `ARCHITECTURE.md` for design details

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
