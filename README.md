# Introduction 
This repository is one of three repositories which make up the Azure Data Factory DataOps Demonstation:

* **Infrastructure** (*this repository*) - Contains a set of Bicep templates for provisioning all infrastructure for the demo as well as JSON exports of all the Azure DevOps Build and Release Pipelines
* **AzureSQL** - Contains the Azure SQL Database project files (SSDT) for maintaining all database objects within Visual Studio (2017-2022)
* **DataFactory** - Contains all the Azure Data Factory objects (linked services, data-sets and pipelines) for this demo - this repository should be connected to the Development instance of DataFactory.

# Getting Started
Navigate to each of the following folders for more information on how to deploy the Azure DevOps pipelines as well as infrastructure:

* **devops-pipelines** - contains the JSON exports for both Build and Release pipelines
* **templates** - contains all the Bicep modules required for infrastructure deployment.

---
THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
