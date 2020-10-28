import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class ExpressionApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getDEGTable(searchIterm: ExprSearch): Observable<any> {
    return this.getData('expression/degtable', {
      symbol: searchIterm.validSymbol,
      cancertypes: searchIterm.cancerTypesSelected,
    });
  }
}
