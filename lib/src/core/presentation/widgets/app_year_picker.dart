import 'package:bits_goals_module/src/core/domain/value_objects/year.dart';
import 'package:flutter/material.dart';

// TODO: Refactor to use DateTime instead of Year Value Object.
class AppYearPicker extends StatefulWidget {
  final Year firstYear;
  final Year lastYear;
  final Year preSelectedYear;
  final List<Year> unavailableYears;
  final void Function(Year) onChanged;

  const AppYearPicker({
    super.key,
    required this.firstYear,
    required this.lastYear,
    required this.preSelectedYear,
    required this.unavailableYears,
    required this.onChanged,
  });

  @override
  State<AppYearPicker> createState() => _AppYearPickerState();
}

class _AppYearPickerState extends State<AppYearPicker> {
  late final ScrollController _scrollController;
  bool hideFirstDivider = true;

  void _listenToScroll() {
    if (_scrollController.offset == 0) {
      setState(() {
        hideFirstDivider = true;
      });
    } else if (hideFirstDivider) {
      setState(() {
        hideFirstDivider = false;
      });
    }
  }

  @override
  void initState() {
    _scrollController = ScrollController(
      initialScrollOffset: 0,
    );
    _scrollController.addListener(_listenToScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_listenToScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = widget.lastYear.value - widget.firstYear.value + 1;
    return Flexible(
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: hideFirstDivider ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: const Divider(
              thickness: 0,
              height: 0,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 16;
                const double buttonWidth = _YearButton.width;
                final int crossAxisCount =
                    constraints.maxWidth ~/ (buttonWidth + spacing);
                return GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final int currentYearValue = widget.firstYear.value + index;
                    // TODO: Do not instantiate domain types in presentation
                    final currentYear = Year.fromInt(currentYearValue);
                    final bool isSelected =
                        currentYear.value == widget.preSelectedYear.value;
                    final bool isUnavailable = widget.unavailableYears
                        .any((y) => y.value == currentYearValue);
                    return _YearButton(
                      year: currentYear,
                      isSelected: isSelected,
                      isUnavailable: isUnavailable,
                      onChanged: widget.onChanged,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(
            thickness: 0,
            height: 0,
          ),
        ],
      ),
    );
  }
}

class _YearButton extends StatelessWidget {
  final Year year;
  final bool isSelected;
  final bool isUnavailable;
  final void Function(Year) onChanged;

  const _YearButton({
    required this.year,
    required this.isSelected,
    required this.isUnavailable,
    required this.onChanged,
  });

  static const double width = 64;

  @override
  Widget build(BuildContext context) {
    const BorderRadius borderRadius = BorderRadius.all(
      Radius.circular(24),
    );
    final theme = Theme.of(context);
    Color? backgroundColor;
    Color textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isUnavailable) {
      textColor = theme.disabledColor;
    } else {
      backgroundColor = theme.primaryColor.withValues(alpha: 0.08);
    }

    return InkWell(
      onTap: isUnavailable ? null : () => onChanged(year),
      borderRadius: borderRadius,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          year.value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
