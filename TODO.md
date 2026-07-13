# TODO - GitHub Sign-In (FirebaseAuth) integration

- [x] Verify current auth implementation (GithubAuthProvider + signInWithProvider).
- [ ] Ensure LoginScreen uses correct auth controller action for GitHub (already present).
- [ ] Ensure Auth flow routes correctly to BiometricsScreen / unlock.
- [ ] If GitHub provider requires web redirect/handler: add/confirm any needed flutter_web_auth_2 (only if platform is web).
- [ ] Handle linking conflicts (Google vs GitHub) if same email exists: decide on Firebase account linking strategy.
- [ ] Improve UX: show loading + disable buttons + error snackbar.


