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

  public getDEGTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/degtable', postTerm);
  }
  public getDEGPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/degplot', postTerm);
  }
}
