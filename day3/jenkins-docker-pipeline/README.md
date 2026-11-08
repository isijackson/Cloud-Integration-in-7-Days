# Day 3, part one: the brewery's Jenkins pipeline

Book: **Day 3: Containers and the orchestra**, Afternoon, part one: the brewery's pipeline, Steps 1 to 12. Script comments call this "Week 3 Lab 3.3".

Jenkins runs in a Docker container on your laptop with the Docker socket mounted. A pipeline job, `menu-board`, checks out the menu-board source, builds an NGINX image with the menu page, smoke-tests it, tags it with the build number and `latest`, and pushes it to a registry with a stored credential. A second build adds a third beer; Step 11 rolls a taproom back to tag 1.

## Files

| File | What it does |
|---|---|
| `menu-board/index.html` | The whole product: the brewery's name and two beers. Step 10 adds a third. |
| `menu-board/Dockerfile` | `FROM nginx:1.27-alpine`, copies `index.html`. |
| `menu-board/Jenkinsfile` | The pipeline: checkout, build, smoke test, push `:BUILD_NUMBER` and `:latest`. Reads `IMAGE_NAME` from the environment, falling back to the placeholder `YOUR_DOCKERHUB_USER/menu-board`, and the credential ID `dockerhub-credentials`. |
| `menu-board/Jenkinsfile.ai-review` | Stretch, not yet run in class: the same pipeline with a stage that has a local open-weight model (Docker Model Runner, `ai/smollm2`) review the Dockerfile and archive the review as a build artifact. |
| `menu-board/.github/workflows/build.yml` | The same build as GitHub Actions (stretch); reads the repository secrets `DOCKERHUB_USER` and `DOCKERHUB_TOKEN`. |
| `jenkins/Dockerfile` | The course's Jenkins image: the Docker CLI, four plugins and a start-up script baked in. |
| `jenkins/init.groovy.d/setup.groovy` | Start-up script: the `admin` account, the registry credential when `REG_USER` and `REG_PASS` are set, and the job when `REPO_URL` is set. |
| `jenkins/job-config.xml` | The `menu-board` job definition the start-up script creates. |
| `scripts/deploy-lab3-2.sh` | Steps 1, 2, 5, 6, 7, 8 and 10: a private registry on `localhost:5005`, the Jenkins image, the source in a bare Git repository in the Docker volume `brewlab-git`, the credential, the job and two builds. Needs no account. |
| `scripts/rollback-lab3-2.sh [-n] [-y]` | Removes the Jenkins and registry containers, containers started from the menu-board images, the volume, the network and the built images. |

## Prerequisites

- **Tools** (Day 0): Docker Desktop, running; `git`, `curl`; `gh` only if you push the source to GitHub. No cloud CLI and no Cloud Shell.
- **Accounts:** none for the script route. For Docker Hub: an account and a personal access token with Read and Write scope (Account settings, Personal access tokens). A GitHub account is optional.
- **Check:**

```bash
cd ~/Cloud-Integration-in-7-Days/day3/jenkins-docker-pipeline
docker info --format '{{.ServerVersion}}'
gh auth status
```

"Cannot connect to the Docker daemon" means open Docker Desktop and wait.

## Mac and Windows

- **Mac.** Nothing extra.
- **Windows (WSL Ubuntu).** Docker Desktop's WSL integration for Ubuntu must be on, because Step 2 mounts `/var/run/docker.sock`, which only exists inside Ubuntu with the integration on. Run every command in the Ubuntu terminal; http://localhost:8080 opens in the Windows browser, or with `explorer.exe http://localhost:8080`.

## Values to edit first

| Item | Book value | Where |
|---|---|---|
| Image name on Docker Hub | `<your-dockerhub-user>/menu-board` | Step 7: replace `YOUR_DOCKERHUB_USER/menu-board` on the `IMAGE_NAME` line of `Jenkinsfile` (the script route passes `IMAGE_NAME` and skips this) |
| Registry for the script | `localhost:5005`, user `brewer` | `REGISTRY_HOST=index.docker.io REG_USER=<user> REG_PASS=<token>` to push to Docker Hub instead |
| Git remote | `https://github.com/<you>/menu-board.git` | Step 1, if you use GitHub |

Step 1's `git init` inside `menu-board/` makes a repository inside your clone of this one; copy it out first to keep them apart:

```bash
cp -r menu-board ~/menu-board && cd ~/menu-board
```

## Run order

**By hand (do this first).** Steps 1 to 12. Step 2 builds and starts Jenkins:

```bash
docker build -t it360-jenkins jenkins/
docker network create brewlab
docker run -d --name jenkins --network brewlab -e SMOKE_NET=brewlab \
    -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock it360-jenkins
docker ps --format '{{.Names}}  {{.Ports}}'
```

Then sign in at http://localhost:8080 (Step 3), make the Docker Hub token (Step 4), store it in Jenkins with the ID `dockerhub-credentials` (Step 5), create the pipeline job (Step 6), set the image name (Step 7), Build Now (Step 8), and continue with Steps 9 to 12.

**Scripted:**

```bash
bash scripts/deploy-lab3-2.sh
```

Then open http://localhost:8080 (user `admin`, password `admin`) to read the screens. Without the Docker Hub trio the script generates a registry password and prints it on its last line. Steps 9, 11 and 12 are checks you run yourself.

## Expected result

`docker ps` shows `jenkins` with `0.0.0.0:8080->8080/tcp`; the job's console log ends in `SUCCESS` after checkout, build, an HTTP 200 smoke test, a masked login and two pushes; the registry lists tags `1`, `2` and `latest`; a container from tag 2 serves three beers and one from tag 1 serves two; and no build log contains the registry password. The scripted run takes about 3 minutes.

## Clean up

```bash
bash scripts/rollback-lab3-2.sh -y
```

By hand: `docker rm -f jenkins registry`, `docker volume rm brewlab-git`, `docker network rm brewlab`, then `docker rmi it360-jenkins` and the `menu-board` images by name (for example `docker rmi localhost:5005/bonneville/menu-board:1`, `:2` and `:latest`, or `<user>/menu-board:...` on Docker Hub). `docker stop` any `menu-board` container from Steps 10 to 12 first. On hub.docker.com, delete the test repository if you made one, and delete the access token you used today.

## Cost

Nothing. Jenkins and the registry are containers on your machine, and Docker Hub's free plan includes the one repository this lab needs. Budget about 4 GB of disk.

## Do not skip

The credential ID must be spelled `dockerhub-credentials`, because the Jenkinsfile looks it up by that string. Store a Docker Hub access token, never your account password. If the real token ever appears in a build log, stop, rotate it on Docker Hub, and find the step that printed it.

## When something fails

See the chapter's "If it fails" lines and field notes, the "Troubleshoot with an AI assistant" subsection of this lab, and Appendix C, "Day 3".
