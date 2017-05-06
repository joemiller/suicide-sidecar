suicide-sidecar
===============

A small sidecar container to watch for changes in SecretVolumes (or ConfigMaps,
or any other path) and execute a deletion of the pod so that it can be restarted.

In an ideal world, your application watches for changes in SecretVolumes and
reloads those secrets on the fly. This is not always possible such as third-party
applications which you can't modify. In these cases the suicide-sidecar is a
useful assistant that provides automatic restarts so that the app can reload
updated Secrets. Automatic restarts on secret updates improves security by
making it easier to rotate secrets frequently.

This is especially useful for **TLS certificates** since many applications and
libraries only support loading certificates at startup. Automated reloading
of TLS certificates promotes shorter validity periods which increases
security.

How it works
------------

The container uses `inotifywait` from the [inotify-tools](https://github.com/rvoicilas/inotify-tools) suite to wait for
changes to monitored files or directories and then executes `kubectl delete pod $POD_NAME`.

Usage
-----

- The container takes at least one command line argument - a path to watch.
  Multiple paths may be specified.
- The container needs the `POD_NAME` and `NAMESPACE` provided as environment variables
  using the downward API.
- The container must have access to execute `kubectl delete pod` against itself.
  This is the case in most Kubernetes installations.

Add the sidecar container to your Pod spec:

```
spec:
  containers:
    # suicide sidecar
    - name: suicide-sidecar
      # TODO: build number not version
      image: quay.io/getpantheon/suicide-sidecar:shell-version
      imagePullPolicy: Always
      args:
        - /secretvol
      env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      volumeMounts:
        - mountPath: /secretvol
          name: secret

  volumes:
    - name: secret
      secret:
        secretName: my-apps-secrets
```

### Optional Parameters

- `KUBECTL_OPTIONS` - Set this environment variable if you need to modify the
  options passed to the `kubectl get pod` and `kubectl delete pod` actions.
- `INOTIFYWAIT_OPTIONS` - Override options passed to the `inotifywait` command.

Demo
----

Run the demo script for an example in action:

```
$ bash demo/demo.sh

==> Creating 'suicide-sidecar-test' pod
secret "suicide-secret-test" created
pod "suicide-sidecar-test" created

==> Waiting for pod to enter Running state
suicide-sidecar-test   0/2       ContainerCreating   0         2s
suicide-sidecar-test   0/2       ContainerCreating   0         3s
suicide-sidecar-test   0/2       ContainerCreating   0         5s
suicide-sidecar-test   0/2       ContainerCreating   0         6s
suicide-sidecar-test   0/2       ContainerCreating   0         8s
suicide-sidecar-test   2/2       Running   0         9s

==> Modifying secret volume
secret "suicide-secret-test" configured

==> Tailing logs (expect up to a minute wait for the secretVolume to be updated by Kubernetes)
|suicide-sidecar-test::suicide-sidecar | Setting up watches.
|suicide-sidecar-test::suicide-sidecar | Watches established.
|suicide-sidecar-test::suicide-sidecar | /secretvol/ DELETE,ISDIR ..5985_06_05_15_00_39.776133745
|suicide-sidecar-test::suicide-sidecar | pod "suicide-sidecar-test" deleted

==> Cleaning up kube resources
pod "suicide-sidecar-test" deleted
secret "suicide-secret-test" deleted
```
