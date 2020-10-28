import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
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
    return this.postData('expression/degtable', {
      symbol: searchIterm.validSymbol,
      cancertypes: searchIterm.cancerTypesSelected,
    }).pipe(map((res) => res.cj));
  }
}
