import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { FormControl } from '@angular/forms';
import symbolList from 'src/app/shared/constants/symbollist';
const symbolListLower = symbolList.map((v) => v.toLowerCase().replace(/[^0-9a-z]+/g, ''));
import cancerTypeList from 'src/app/shared/constants/cancertypelist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-search-box',
  templateUrl: './search-box.component.html',
  styleUrls: ['./search-box.component.css'],
})
export class SearchBoxComponent implements OnInit {
  exampleGeneList =
    'A2M ACE ANGPT2 BPI CD1B CDR1 EGR2 EGR3 HBEGF HERPUD1 MCM2 MRE11A PCTP PODXL; PPAP2B PPY PTGS2, RCAN1 SLC4A7 THBD THB-d';
  exampleCancerTypes = ['KICH', 'KIRC', 'KIRP', 'LUAD', 'LUSC'];
  cancerTypeList = cancerTypeList;
  inputString = '';
  cancerTypeSelected = new FormControl();

  @Output() $searchSelected = new EventEmitter<ExprSearch>();

  constructor() {}

  ngOnInit(): void {}

  public showExample(): void {
    this.inputString = this.exampleGeneList;
    this.cancerTypeSelected.patchValue(this.exampleCancerTypes);
  }

  public submit(str: string): void {
    this.inputString = this._getSearchSymbol(str).join(', ');

    const searchTerm = {
      validSymbol: this._getSearchSymbol(str),
      cancerTypeSelected: this.cancerTypeSelected.value,
    };

    if (!searchTerm.cancerTypeSelected || searchTerm.cancerTypeSelected.length < 1) {
      window.alert('please select at least one cancer type');
      return;
    }
    if (searchTerm.validSymbol.length < 1) {
      window.alert('please input at least one gene symbol');
      return;
    }
    this.$searchSelected.emit(searchTerm);
  }

  public clear(): void {
    this.inputString = '';
    this.cancerTypeSelected.patchValue([]);
  }

  private _getSearchSymbol(str: string): string[] {
    const arr = str
      .split(/\s|,|;/)
      .filter(Boolean)
      .map((v) => v.toLowerCase().replace(/[^0-9a-z]+/g, ''))
      .filter((item, pos, self) => self.indexOf(item) === pos)
      .sort();

    return arr
      .map((v) => {
        const ind = symbolListLower.indexOf(v);
        return symbolList[ind];
      })
      .filter(Boolean);
  }
}
