import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { SnvComponent } from './snv.component';

describe('SnvComponent', () => {
  let component: SnvComponent;
  let fixture: ComponentFixture<SnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ SnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
