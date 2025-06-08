import 'package:flutter/material.dart';

class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final int initialLoadCount;
  final int loadMoreCount;
  final ScrollController? scrollController;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialLoadCount = 10,
    this.loadMoreCount = 10,
    this.scrollController,
    this.hasMore = true,
    this.onLoadMore,
    this.loadingWidget,
    this.emptyWidget,
    this.padding,
    this.physics,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _currentCount = widget.initialLoadCount;
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoading && widget.hasMore && widget.onLoadMore != null) {
      setState(() {
        _isLoading = true;
      });

      await widget.onLoadMore!();

      if (mounted) {
        setState(() {
          _currentCount += widget.loadMoreCount;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: _currentCount + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return widget.loadingWidget ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        return widget.itemBuilder(context, widget.items[index]);
      },
    );
  }
}
