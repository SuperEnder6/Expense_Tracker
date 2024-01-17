import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Transaction> transactions = [];

  void addTransaction(String title, double amount, bool isDailyExpense, DateTime date) {
    setState(() {
      transactions.add(Transaction(title, amount, isDailyExpense, date));
    });
  }

  double get totalAmount {
    return transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }

  List<charts.Series<Transaction, DateTime>> _createSampleData() {
    return [
      charts.Series<Transaction, DateTime>(
        id: 'Transactions',
        domainFn: (Transaction transaction, _) => transaction.date,
        measureFn: (Transaction transaction, _) => transaction.amount,
        data: transactions,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TransactionList(transactions),
            TransactionForm(addTransaction),
            TotalAmountDisplay(totalAmount),
            Chart(_createSampleData()),
          ],
        ),
      ),
    );
  }
}

class Transaction {
  final String title;
  final double amount;
  final bool isDailyExpense;
  final DateTime date;

  Transaction(this.title, this.amount, this.isDailyExpense, this.date);
}

class TransactionForm extends StatefulWidget {
  final Function(String, double, bool, DateTime) addTransaction;

  TransactionForm(this.addTransaction);

  @override
  _TransactionFormState createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  bool isDailyExpense = true;
  DateTime selectedDate = DateTime.now();

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate != null && pickedDate != selectedDate) {
        setState(() {
          selectedDate = pickedDate;
        });
      }
    });
  }

  void submitForm() {
    final title = titleController.text;
    final amount = double.parse(amountController.text);

    if (title.isEmpty || amount <= 0) {
      return;
    }

    widget.addTransaction(title, amount, isDailyExpense, selectedDate);
    titleController.clear();
    amountController.clear();
    setState(() {
      isDailyExpense = true;
      selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: '項目名稱'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => submitForm(),
              decoration: InputDecoration(labelText: '金額'),
            ),
            Row(
              children: [
                Text('類型:'),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text('日常消費'),
                  selected: isDailyExpense,
                  onSelected: (selected) {
                    setState(() {
                      isDailyExpense = selected;
                    });
                  },
                ),
                SizedBox(width: 10),
                ChoiceChip(
                  label: Text('額外消費'),
                  selected: !isDailyExpense,
                  onSelected: (selected) {
                    setState(() {
                      isDailyExpense = !selected;
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text('日期:'),
                SizedBox(width: 10),
                Text(DateFormat.yMd().format(selectedDate)),
                SizedBox(width: 10),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: Text('選擇日期'),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: submitForm,
              child: Text('新增交易'),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  TransactionList(this.transactions);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions.map((transaction) {
        return Card(
          color: transaction.isDailyExpense ? Colors.green[100] : Colors.orange[100],
          child: ListTile(
            title: Text(transaction.title),
            subtitle: Text('\$${transaction.amount.toStringAsFixed(2)}'),
            trailing: Text(DateFormat.yMd().format(transaction.date)),
          ),
        );
      }).toList(),
    );
  }
}

class TotalAmountDisplay extends StatelessWidget {
  final double totalAmount;

  TotalAmountDisplay(this.totalAmount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        '總消費金額: \$${totalAmount.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class Chart extends StatelessWidget {
  final List<charts.Series<Transaction, DateTime>> seriesList;

  Chart(this.seriesList);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: charts.TimeSeriesChart(
        seriesList,
        animate: true,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
      ),
    );
  }
}
