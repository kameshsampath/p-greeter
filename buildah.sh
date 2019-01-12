#!/bin/bash -x

# define the container base image
javacontainer=$(buildah from registry.fedoraproject.org/fedora-minimal)
# mount the container root FS
javamnt=$(buildah mount "$javacontainer")

# make the java app directory
mkdir -pv "$javamnt/work"

# copy the application jar, with Knative build templates, the app sources gets loaded in the /workspace directory
# adjust application name accordingly
if [ -z "$CONTEXT_DIR"  ] || [ "$CONTEXT_DIR" = "." ] 
then
  cp -v "/workspace/target/${JAVA_APP_NAME}" "$javamnt/work/app"
else
  cp -v "/workspace/${CONTEXT_DIR}/target/${JAVA_APP_NAME}" "$javamnt/work/app"
fi

chmod -R 755 "$javamnt/work"

buildah config --workingdir /work "$javacontainer"
buildah config --port 8080
buildah config --entrypoint '["./app","-Dshamrock.http.host=0.0.0.0"]' "$javacontainer"

imageID=$(buildah commit "$javacontainer" "$IMAGE_NAME")

# Push the image back to local default docker registry
# you can also push to external registry 
# Refer to https://github.com/containers/buildah/blob/master/docs/buildah-push.md

# HTTPS
# buildah push --cert-dir=/var/run/secrets/kubernetes.io \
#   --creds=openshift:$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \
#    $imageID \
#    docker://docker-registry.default.svc.cluster.local:5000/$IMAGE_NAME

## HTTP
buildah push --tls-verify=false \
  --creds=openshift:"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
   "$imageID" \
   "docker://docker-registry.default.svc:5000/$POD_NAMESPACE/$IMAGE_NAME"
