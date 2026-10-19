// SPDX-License-Identifier: Apache-2.0
#include <clocale>
#include <cstdlib>
#include <iostream>
#include "btop_locale.hpp"
#include "btop_tools.hpp"

static void check(bool condition, const char* message) {
 if (!condition) { std::cerr << message << '\n'; std::exit(1); }
}
int main() {
 check(std::setlocale(LC_ALL, "en_US.UTF-8") != nullptr, "UTF-8 locale unavailable");
 check(Locale::init("zh"), "Chinese init");
 check(Locale::currentLanguage() == "zh", "Chinese state");
 check(Locale::get("Help") == "帮助", "Chinese lookup");
 check(Locale::get("total") == "CPU 总占用率", "CPU graph field label");
 check(Locale::get("gpu-totals") == "各 GPU 占用率", "GPU graph field label");
 check(Locale::get("Load avg:") == "平均负载：", "Load average label");
 check(Locale::get("tree") == "进程树", "Process tree label");
 check(Locale::get("ignals") == "发送信号", "Signal action is explicit");
 check(Locale::get("Renice PID ") == "进程 PID ", "Priority dialog does not imply changing PID");
 check(Locale::get("cpu lazy") == "CPU 平均", "Average CPU sorting label");
 check(Locale::get("show_swap") == "显示交换内存", "Swap is not necessarily a partition");
 check(Locale::get("Stopped") == "已暂停", "Stopped process is suspended");
 check(Locale::get("Tracing") == "调试暂停", "Tracing state differs from following a process");
 check(Locale::optionDescription("color_theme").front() == "设置界面颜色主题。", "Chinese option description");
 check(Locale::optionDescription("proc_tree").front() == "以树状结构显示进程。", "Process option description");
 check(Locale::optionDescription("missing").empty(), "Missing option fallback");
 auto missing = Locale::get(std::string("missing temporary key"));
 check(missing == "missing temporary key", "Fallback lifetime");
 check(Locale::reload() && Locale::get("Help") == "帮助", "Reload language");
 check(Locale::init("en") && Locale::get("Help") == "Help", "English clears Chinese");
 check(Locale::get("Key:") == "Key:", "English has no unconditional Chinese");
 check(Locale::optionDescription("color_theme").empty(), "English option description fallback");
 check(!Locale::init("invalid") && Locale::currentLanguage() == "en", "Invalid language fallback");
 check(Locale::init("zh"), "Switch back to Chinese");
 using namespace Tools;
 check(wide_ulen("中文A") == 5, "Mixed width");
 const std::string bounded = "中文extra";
 check(wide_ulen(std::string_view(bounded.data(), 6)) == 4, "Bounded view");
 check(wide_ulen("e\xcc\x81") == 1, "Combining mark width");
 check(uresize("中文A", 3, true) == "中", "UTF-8 prefix clipping");
 check(luresize("A中文", 3, true) == "文", "UTF-8 suffix clipping");
 check(ljust("中文", 5, true, true) == "中文 ", "Left padding");
 check(rjust("中文", 5, true, true) == " 中文", "Right padding");
 check(cjust("中文", 3, true, true) == " 中", "Clipped centered padding");
 check(ljust("中文", 1, true, true) == " ", "Narrow cell padding");
 check(ljust("中文", 1, true, true, false) == "中文", "No underflow without clipping");
 check(wide_ulen("\x1b[1m中文\x1b[0m") == 4, "ANSI styling has zero width");
 check(wide_ulen(std::string("\xff", 1)) == 1, "Invalid UTF-8 bounded fallback");
 std::cout << "Chinese locale and terminal width checks passed\n";
}
