val local_test :
  ocluster:Cluster_api.Raw.Client.Submission.t Capnp_rpc_lwt.Sturdy_ref.t ->
  repo:Current_github.Repo_id.t ->
  Fpath.t ->
  unit ->
  unit Current.t
(** [local_test ~ocluster repo] is a pipeline that tests the local git repository [repo] as the CI would.
    The git HEAD is the "PR" to be compared with master. *)

val v :
  ocluster:Cluster_api.Raw.Client.Submission.t Capnp_rpc_lwt.Sturdy_ref.t ->
  app:Current_github.App.t ->
  unit -> unit Current.t
(** The main opam-repo-ci pipeline. Tests everything configured for GitHub application [app]. *)
