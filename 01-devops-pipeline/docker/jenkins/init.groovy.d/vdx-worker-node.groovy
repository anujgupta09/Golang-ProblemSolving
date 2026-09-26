// Idempotently creates the vdx-worker inbound agent node and publishes its
// connection secret for scripts/jenkins-env.sh to read via `podman exec`. Runs as
// SYSTEM on every controller boot; see README.md
// section 4. Field values here must match the `-workDir` etc. flags used to
// launch the vdx-worker container in scripts/jenkins-env.sh's agent().
import jenkins.model.Jenkins
import hudson.model.Node
import hudson.slaves.DumbSlave
import hudson.slaves.JNLPLauncher
import hudson.slaves.RetentionStrategy

def NODE_NAME = 'vdx-worker'
def REMOTE_FS = '/workspace/agent'
def LABEL = 'vdx-podman'
def SECRET_FILE = new File('/var/jenkins_home/vdx-worker-secret')

try {
    def jenkins = Jenkins.get()
    def node = jenkins.getNode(NODE_NAME)
    if (node == null) {
        node = new DumbSlave(NODE_NAME, REMOTE_FS, new JNLPLauncher(true))
        node.setNumExecutors(1)
        node.setLabelString(LABEL)
        node.setMode(Node.Mode.EXCLUSIVE)
        node.setRetentionStrategy(new RetentionStrategy.Always())
        jenkins.addNode(node)
        println("vdx-worker-node: created node '${NODE_NAME}'")
    } else {
        println("vdx-worker-node: node '${NODE_NAME}' already exists, leaving it as-is")
    }

    def computer = jenkins.getComputer(NODE_NAME)
    def secret = computer?.getJnlpMac()
    if (secret) {
        SECRET_FILE.text = secret
        // owner-only, matches the chmod 600 used for every other secret file in this pipeline
        SECRET_FILE.setReadable(false, false)
        SECRET_FILE.setWritable(false, false)
        SECRET_FILE.setReadable(true, true)
        SECRET_FILE.setWritable(true, true)
        println("vdx-worker-node: wrote agent secret to ${SECRET_FILE}")
    } else {
        println("vdx-worker-node: WARNING could not resolve a computer/secret for '${NODE_NAME}' yet")
    }
} catch (Throwable t) {
    println("vdx-worker-node: FAILED - ${t}")
    t.printStackTrace()
}
