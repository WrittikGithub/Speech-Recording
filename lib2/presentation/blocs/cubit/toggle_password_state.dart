part of 'toggle_password_cubit.dart';

@immutable
Widget togglePassword() {
    return BlocBuilder<TogglepasswordCubit, bool>(
      builder: (context, state) {
        return InkWell(
  onTap: () {
    context.read<TogglepasswordCubit>().togglePassword();
  },
  child: Icon(
    state 
      ? Icons.visibility
      : Icons.visibility_off,
    color: Appcolors.kpurplelightColor,
  ),
);
      },
    );
  }