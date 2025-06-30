

# 🐳 Dev Container Configuration Documentation

## 📋 Overview

This dev container configuration creates a comprehensive development environment for Django portfolio project with Azure deployment capabilities. It combines Django development with Azure CLI and Terraform for Infrastructure as Code, specifically designed for EPAM SECLAB UA Capstone projects.

---

## 🏗️ Configuration Breakdown

### **Base Image**
```json
"image": "mcr.microsoft.com/devcontainers/universal:2"
```

**Description:** Microsoft Universal Dev Container image with pre-installed development tools
- **Size:** ~6GB with comprehensive tooling
- **Includes:** Python 3.12, Node.js, Git, Docker, and 20+ development tools
- **Benefits:** 
  - Zero manual tool installation
  - Consistent across all developers
  - Regular Microsoft updates and security patches

---

### **Features Integration**

#### **Azure CLI**
```json
"ghcr.io/devcontainers/features/azure-cli:1": {
  "version": "latest"
}
```

**Capabilities:**
- Full Azure CLI functionality for cloud resource management
- Authentication and subscription management
- Resource deployment and monitoring
- Integration with Azure DevOps and GitHub Actions

**Use Cases:**
- Deploy infrastructure to Azure
- Manage Azure resources from command line
- Configure CI/CD pipelines
- Monitor application performance

#### **Terraform**
```json
"ghcr.io/devcontainers/features/terraform:1": {
  "version": "latest"
}
```

**Capabilities:**
- Infrastructure as Code (IaC) provisioning
- Multi-cloud resource management
- State management and version control
- Plan and apply infrastructure changes

**Use Cases:**
- Define Azure infrastructure in code
- Version control infrastructure changes
- Automated deployment pipelines
- Environment consistency (dev/staging/prod)

---

### **Resource Requirements**

```json
"hostRequirements": {
  "cpus": 4,
  "memory": "4gb",
  "storage": "64gb"
}
```

| Resource | Allocation | Justification |
|----------|------------|---------------|
| **CPU** | 4 cores | Django development + Docker + VS Code IntelliSense |
| **Memory** | 4GB | Universal image + Python packages + IDE |
| **Storage** | 64GB | Source code + Docker images + dependencies |

**Performance Impact:**
- Faster container startup and build times
- Smooth VS Code experience with extensions
- Concurrent Django server and development tools

---

### **Lifecycle Commands**

#### **Creation Sequence**
```json
"waitFor": "onCreateCommand"
```
**Purpose:** Ensures container waits for initial setup completion before user access

#### **Content Updates**
```json
"updateContentCommand": "pip install -r requirements.txt && python manage.py migrate"
```
**Execution:** Runs when container is rebuilt or repository updates
**Actions:**
1. Install/update Python dependencies
2. Apply database migrations
3. Prepare development environment

#### **Post Creation**
```json
"postCreateCommand": "cp .env.example .env"
```
**Purpose:** One-time setup after container creation
**Result:** Creates local environment configuration file

#### **Attach Command**
```json
"postAttachCommand": {
  "server": "python manage.py runserver"
}
```
**Execution:** Every time user connects to the container
**Result:** Automatically starts Django development server on port 8000

---

### **VS Code Customizations**

#### **Auto-opened Files**
```json
"openFiles": [
  "project_portfolio/templates/index.html"
]
```
**Purpose:** Immediately shows main template file for quick development start

#### **Essential Extensions**
```json
"extensions": [
  "ms-python.python",                    // Python language support
  "hashicorp.terraform",                 // Terraform syntax and validation
  "ms-azuretools.vscode-azureterraform", // Azure-Terraform integration
  "ms-azuretools.vscode-azurecli"        // Azure CLI integration
]
```

**Extension Benefits:**
- **Python:** IntelliSense, debugging, linting, formatting
- **Terraform:** Syntax highlighting, validation, auto-completion
- **Azure Terraform:** Azure resource templates and snippets
- **Azure CLI:** Command palette integration and Azure resource explorer

#### **Terraform Configuration**
```json
"terraform.languageServer.enable": true,
"terraform.validation.enableEnhancedValidation": true
```
**Features:**
- Real-time syntax validation
- Resource documentation on hover
- Auto-completion for Azure resources
- Error detection and suggestions

---

### **Port Configuration**

```json
"portsAttributes": {
  "8000": {
    "label": "Application",
    "onAutoForward": "openPreview"
  }
},
"forwardPorts": [8000]
```

**Port 8000 Configuration:**
- **Label:** "Application" (appears in Ports panel)
- **Auto-forward:** Automatically opens in browser preview
- **Protocol:** HTTP (Django development server)

**User Experience:**
- Instant access to running Django application
- No manual port forwarding required
- Seamless development workflow

---

## 🚀 Development Workflow

### **Container Startup Sequence**
1. **Image Pull:** Downloads Universal base image (~6GB)
2. **Feature Installation:** Installs Azure CLI and Terraform
3. **Environment Setup:** Copies .env.example to .env
4. **Dependencies:** Installs Python packages from requirements.txt
5. **Database:** Runs Django migrations
6. **Server Start:** Launches Django development server
7. **IDE Ready:** Opens VS Code with extensions loaded

### **Expected Timeline**
- **First Setup:** 5-8 minutes (image download + features)
- **Subsequent Starts:** 2-3 minutes (cached images)
- **Code Changes:** Instant hot reload

---

## 💡 Use Cases and Benefits

### **For Django Development**
- **Instant Setup:** No Python/Django installation required
- **Consistent Environment:** Same setup across all developers
- **Integrated Tools:** Database, server, and IDE in one container

### **For Azure Deployment**
- **Cloud-Ready:** Azure CLI pre-configured for deployments
- **Infrastructure as Code:** Terraform for reproducible infrastructure
- **CI/CD Integration:** Easy GitHub Actions integration

### **For Learning and Training**
- **EPAM SECLAB UA Compliance:** Meets academic project requirements
- **Professional Tools:** Industry-standard development environment
- **Documentation:** Built-in help and autocomplete for Azure resources

---

## 🔧 Customization Options

### **Performance Optimization**
```json
// For better performance on limited resources
"hostRequirements": {
  "cpus": 2,
  "memory": "3gb",
  "storage": "32gb"
}
```

### **Additional Extensions**
```json
"extensions": [
  // Existing extensions...
  "ms-python.black-formatter",     // Code formatting
  "ms-python.isort",               // Import sorting
  "GitHub.copilot",                // AI code assistance
  "bradlc.vscode-tailwindcss"      // CSS framework support
]
```

### **Environment Variables**
```json
"remoteEnv": {
  "DJANGO_SETTINGS_MODULE": "project_portfolio.settings",
  "DEBUG": "True",
  "DATABASE_URL": "sqlite:///db.sqlite3"
}
```

---

## 🚨 Troubleshooting

### **Common Issues**

#### **"No space left on device"**
**Solution:** Increase storage allocation
```json
"hostRequirements": {
  "storage": "128gb"  // Increase storage
}
```

#### **Slow startup**
**Solution:** Use Python-specific image for faster startup
```json
"image": "mcr.microsoft.com/devcontainers/python:3.11"
```

#### **Memory issues**
**Solution:** Optimize memory allocation
```json
"hostRequirements": {
  "memory": "6gb"  // Increase memory
}
```

### **Recovery Procedures**
1. **Container Issues:** Rebuild container (Ctrl+Shift+P → "Rebuild Container")
2. **Extension Problems:** Disable/re-enable problematic extensions
3. **Port Conflicts:** Check port availability in Ports panel
4. **Storage Full:** Clear Docker cache or increase storage allocation

---

## 📊 Performance Metrics

### **Startup Performance**
- **Cold Start:** 5-8 minutes (first time)
- **Warm Start:** 2-3 minutes (cached)
- **Code Reload:** <5 seconds (file changes)

### **Resource Usage**
- **CPU:** 15-25% during development
- **Memory:** 2-3GB active usage
- **Storage:** 8-12GB total footprint

### **Network Requirements**
- **Initial Setup:** 6-8GB download
- **Updates:** 100-500MB (feature updates)
- **Development:** Minimal (local development)

---

## 🎯 Best Practices

### **Development Workflow**
1. **Start Container:** Let all initialization complete
2. **Check Ports:** Verify Django server is running on port 8000
3. **Environment:** Confirm .env file is properly configured
4. **Extensions:** Ensure all VS Code extensions are loaded
5. **Testing:** Run `python manage.py check` to validate setup

### **Azure Integration**
1. **Authentication:** Run `az login` for Azure CLI access
2. **Subscription:** Set active subscription with `az account set`
3. **Terraform:** Initialize with `terraform init` in terraform directory
4. **Deployment:** Use integrated terminal for deployment commands

### **Code Quality**
1. **Linting:** Use built-in Python linting and formatting
2. **Version Control:** Commit changes regularly
3. **Testing:** Run Django tests with `python manage.py test`
4. **Documentation:** Keep README.md updated with setup instructions

---

## 📚 Related Documentation

- [Dev Containers Official Docs](https://containers.dev/)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Django Development Guide](https://docs.djangoproject.com/)
- [VS Code Python Extension](https://code.visualstudio.com/docs/python/python-tutorial)

---

## 🏷️ Version Information

| Component | Version | Last Updated |
|-----------|---------|--------------|
| **Base Image** | Universal:2 | Microsoft Managed |
| **Azure CLI** | Latest | Auto-updated |
| **Terraform** | Latest | Auto-updated |
| **Python** | 3.12 | Included in Universal |
| **Node.js** | 18.x | Included in Universal |

---

**Note:** This configuration is optimized for EPAM SECLAB UA Capstone projects and provides a complete development environment for Django applications with Azure deployment capabilities.
