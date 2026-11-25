# Лабораторна робота №3 — послідовний протокол I2C на ПЛІС

Погорєлов Олександр Ігорович, КІ-402. **Варіант 14: I2C, Verilog.**

## Структура

```
rtl/i2c_master.v      Master (Tx): дільник SCL, START/STOP, передача адреси/даних, прийом байта, ACK/NACK
rtl/i2c_slave.v       Slave (Rx): детектор START/STOP, розпізнавання адреси 0x42, прийом/передача байта
tb/tb_i2c.v           тестбенч: clk 50 МГц, reset, шина з підтягуванням, 5 тестів з перевірками
tb/waves.gtkw         набір сигналів для GTKWave
syn/*_top.v           обгортки для синтезу (двонаправлені виводи SCL/SDA)
docs/fsm_*.png        діаграми станів (docs/fsm_diagram.py)
docs/waves/*.png      осцилограми симуляції (GTKWave)
docs/reports/         журнал симуляції, звіти Yosys/nextpnr
run.sh                симуляція і синтез
```

## Параметри

| Параметр | Значення |
|---|---|
| Системний такт `clk` | 50 МГц |
| SCL | 100 кГц (Standard-mode), дільник `CLK_HZ / (4 · SCL_HZ)` = 125 |
| Адреса slave | 7'h42 |
| Транзакція | 1 байт запису або 1 байт читання (читання закінчується NACK майстра) |

## Запуск

Потрібен [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) (`iverilog`, `vvp`, `yosys`, `nextpnr-ice40`, `gtkwave`) у `PATH`.

```bash
./run.sh sim                          # симуляція -> build/i2c.vcd, "RESULT: ALL TESTS PASSED"
gtkwave build/i2c.vcd tb/waves.gtkw   # перегляд осцилограм
./run.sh syn                          # синтез для Lattice iCE40 HX8K, Fmax
```

## Результати

Симуляція (`docs/reports/sim.log`): 10 перевірок PASS — запис 0xA5 і 0x3C (slave прийняв), читання 0x5A і 0xC3
(майстер прийняв), звертання до неіснуючої адреси 0x21 → NACK (`ack_err = 1`).

Синтез (iCE40 HX8K, обмеження 50 МГц):

| Модуль | Logic cells | LUT4 | Тригери | Fmax |
|---|---|---|---|---|
| i2c_master | 124 / 7680 | 101 | 60 | 133.4 МГц |
| i2c_slave | 90 / 7680 | 70 | 38 | 160.8 МГц |
