/*
 * poshub.hpp
 */

#pragma once
#include <string>

struct poshub {
    void Init();
    unsigned short GetWindowWidth();
    unsigned short GetWindowHeight();
    void SetWindowWidth(unsigned short);
    void SetWindowHeight(unsigned short);
    std::string GetTitle();
    void SetTitle(std::string);
    std::wstring GetTitleWide();
    void SetTitleWide(std::wstring);
};