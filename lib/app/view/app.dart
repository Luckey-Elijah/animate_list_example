// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TodoPage());
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TodoBloc(),
      child: const TodoView(),
    );
  }
}

class TodoView extends StatelessWidget {
  const TodoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('todos')),
      body: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TodoBloc, TodoState>(
      listener: (context, state) {
        if (!state.insertIndex.isNegative) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text('Added "${state.todos[state.insertIndex]}"'),
              ),
            );
          listKey.currentState!.insertItem(state.insertIndex);
        }
        if (!state.removeIndex.isNegative) {
          listKey.currentState!.removeItem(
            state.removeIndex,
            (context, animation) {
              return TodoWidget(
                animation: animation,
                label: state.removedLabel,
                onRemoved: () {},
              );
            },
          );
        }
      },
      builder: (context, state) {
        return AnimatedList(
          initialItemCount: state.todos.length + 1,
          key: listKey,
          itemBuilder: (context, index, animation) {
            if (index == state.todos.length) {
              return Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Add a todo',
                    ),
                    onSubmitted: (value) {
                      context.read<TodoBloc>().add(AddTodo(value));
                    },
                  ),
                ),
              );
            }
            return TodoWidget(
              animation: animation,
              label: state.todos[index],
              onRemoved: () => context.read<TodoBloc>().add(RemoveTodo(index)),
            );
          },
        );
      },
    );
  }
}

class TodoWidget extends StatelessWidget {
  const TodoWidget({
    Key? key,
    required this.animation,
    required this.label,
    required this.onRemoved,
  }) : super(key: key);

  final Animation<double> animation;
  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        child: ListTile(
          title: Text(label),
          leading: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onRemoved,
          ),
        ),
      ),
    );
  }
}

abstract class TodoEvent {
  const TodoEvent();
}

class AddTodo extends TodoEvent {
  const AddTodo(this.label);
  final String label;
}

class RemoveTodo extends TodoEvent {
  const RemoveTodo(this.index);
  final int index;
}

class TodoState {
  const TodoState(
    this.todos, {
    this.insertIndex = -1,
    this.removeIndex = -1,
    this.removedLabel = '',
  });

  final List<String> todos;
  final int insertIndex;
  final int removeIndex;
  final String removedLabel;
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState([])) {
    on<AddTodo>((event, emit) {
      final updatedList = [
        ...state.todos,
        event.label,
      ];
      return emit(TodoState(updatedList, insertIndex: updatedList.length - 1));
    });
    on<RemoveTodo>((event, emit) {
      final label = state.todos[event.index];
      return emit(
        TodoState(
          state.todos..removeAt(event.index),
          removeIndex: event.index,
          removedLabel: label,
        ),
      );
    });
  }
}
