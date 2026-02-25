import 'package:bits_goals_module/src/core/presentation/state_management/reactivity_flutter/app_provider.dart';
import 'package:bits_goals_module/src/features/goals_management/application/use_cases/create_annual_revenue_goal/failures/create_annual_revenue_goal_failure_reason.dart';
import 'package:bits_goals_module/src/features/goals_management/presentation/create_annual_revenue_goal/create_annual_revenue_goal_dialog/create_annual_revenue_goal_dialog_view_model.dart';
import 'package:flutter/material.dart';

class FailureCreateAnnualRevenueGoalDialog extends StatelessWidget {
  const FailureCreateAnnualRevenueGoalDialog(
    this.state, {
    super.key,
  });

  final FailureCreateAnnualRevenueGoal state;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.get<CreateAnnualRevenueGoalDialogViewModel>();
    final retryAfterMinutes = state.failure.retryAfter != null
        ? state.failure.retryAfter!.inMinutes
        : 0;
    final durationText = retryAfterMinutes < 1
        ? 'alguns instantes'
        : retryAfterMinutes == 1
            ? '$retryAfterMinutes minuto'
            : '$retryAfterMinutes minutos';
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erro ao criar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Text(
            switch (state.failure.reason) {
              CreateAnnualRevenueGoalFailureReason
                    .annualGoalForYearAlreadyExists =>
                'Já existe uma meta anual para ${state.year.value}. Selecione outro ano ou edite a meta existente.',
              CreateAnnualRevenueGoalFailureReason.unexpected =>
                'Ocorreu um erro inesperado. Tente novamente.',
              CreateAnnualRevenueGoalFailureReason.connectionError =>
                'Ocorreu um erro de conexão. Verifique sua internet e tente novamente.',
              CreateAnnualRevenueGoalFailureReason.pastYear =>
                'Não é possível criar meta para um ano passado. Selecione outro ano.',
              CreateAnnualRevenueGoalFailureReason.permissionDenied =>
                'Você não possui permissão para criar metas anuais. Solicite com o administrador.',
              CreateAnnualRevenueGoalFailureReason.rateLimitExceeded =>
                'Muitas tentativas. Tente novamente em $durationText.',
              CreateAnnualRevenueGoalFailureReason.zeroOrNegativeTarget =>
                'O valor da meta deve ser maior que zero.',
            },
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () {
                  viewModel.initialize();
                },
                child: Text("Tentar novamente"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
