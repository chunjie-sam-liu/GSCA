import { Component, OnInit } from '@angular/core';
import symbolList from 'src/app/shared/constants/symbollist';
const symbolListLower = symbolList.map((v) => v.toLowerCase().replace(/[^0-9a-z]+/g, ''));

@Component({
  selector: 'app-search-box',
  templateUrl: './search-box.component.html',
  styleUrls: ['./search-box.component.css'],
})
export class SearchBoxComponent implements OnInit {
  example = 'A2M ACE ANGPT2 BPI CD1B CDR1 EGR2 EGR3 HBEGF HERPUD1 MCM2 MRE11A PCTP PODXL; PPAP2B PPY PTGS2, RCAN1 SLC4A7 THBD THB-d';
  inputString: string;
  searchString: string[];

  constructor() {}

  ngOnInit(): void {
    this.inputString = this.example;
    this.searchString = this._getSearchSymbol(this.inputString);
  }

  private _getSearchSymbol(str: string): string[] {
    const arr = str
      .split(/\s|,|;/)
      .filter(Boolean)
      .map((v) => v.toLowerCase().replace(/[^0-9a-z]+/g, ''))
      .filter((item, pos, self) => self.indexOf(item) === pos);

    return arr
      .map((v) => {
        const ind = symbolListLower.indexOf(v);
        return symbolList[ind];
      })
      .filter(Boolean);
  }
}
